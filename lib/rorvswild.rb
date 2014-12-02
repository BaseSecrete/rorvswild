require "rorvswild/version"

module RorVsWild
  def self.new(*args)
    Client.new(*args) # Compatibility with 0.0.1
  end

  class Client
    def self.default_config
      {
        api_url: "http://www.rorvswild.com/api",
        explain_sql_threshold: 500,
        log_sql_threshold: 100,
      }
    end

    attr_reader :api_url, :api_key, :app_id, :error, :request, :explain_sql_threshold, :log_sql_threshold

    def initialize(config)
      config = self.class.default_config.merge(config)
      @explain_sql_threshold = config[:explain_sql_threshold]
      @log_sql_threshold = config[:log_sql_threshold]
      @api_url = config[:api_url]
      @api_key = config[:api_key]
      @app_id = config[:app_id]
      setup_callbacks
    end

    def setup_callbacks
      ApplicationController.rescue_from(StandardError, &method(:after_exception))
      ActiveSupport::Notifications.subscribe("sql.active_record", &method(:after_sql_query))
      ActiveSupport::Notifications.subscribe("render_template.action_view", &method(:after_view_rendering))
      ActiveSupport::Notifications.subscribe("process_action.action_controller", &method(:after_http_request))
      ActiveSupport::Notifications.subscribe("start_processing.action_controller", &method(:before_http_request))
    end

    def before_http_request(name, start, finish, id, payload)
      @request = {controller: payload[:controller], action: payload[:action], path: payload[:path]}
      @queries = []
      @views = {}
      @error = nil
    end

    def after_http_request(name, start, finish, id, payload)
      request[:db_runtime] = (payload[:db_runtime] || 0).round
      request[:view_runtime] = (payload[:view_runtime] || 0).round
      request[:other_runtime] = compute_duration(start, finish) - request[:db_runtime] - request[:view_runtime]
      request[:params] = params_filter.filter(payload[:params]) if error
      Thread.new { post_request }
    rescue => exception
      log_error(exception)
    end

    def after_sql_query(name, start, finish, id, payload)
      return if !queries || payload[:name] == "EXPLAIN".freeze
      runtime, sql, plan = compute_duration(start, finish), nil, nil
      file, line, method = extract_file_and_line_from_call_stack(caller)
      # I can't figure out the exact location which triggered the query, so at least the SQL is logged.
      sql, file, line, method = payload[:sql], "Unknow", 0, "Unknow" if !file
      sql = payload[:sql] if runtime >= log_sql_threshold
      plan = explain(payload[:sql], payload[:binds]) if runtime >= explain_sql_threshold
      queries << {file: file, line: line, method: method, sql: sql, plan: plan, runtime: runtime}
    rescue => exception
      log_error(exception)
    end

    def after_view_rendering(name, start, finish, id, payload)
      if views
        if view = views[file = relative_path(payload[:identifier])]
          view[:runtime] += compute_duration(start, finish)
          view[:times] += 1
        else
          views[file] = {file: file, runtime: compute_duration(start, finish), times: 1}
        end
      end
    end

    def after_exception(exception)
      if !exception.is_a?(ActionController::RoutingError)
        file, line = exception.backtrace.first.split(":")
        @error = {
          exception: exception.class.to_s,
          backtrace: exception.backtrace,
          message: exception.message,
          file: relative_path(file),
          line: line.to_i
        }
      end
      raise exception
    end

    #######################
    ### Private methods ###
    #######################

    private

    def queries
      @queries
    end

    def views
      @views
    end

    def slowest_views
      views.values.sort { |h1, h2| h2[:runtime] <=> h1[:runtime] }[0, 25]
    end

    def slowest_queries
      queries.sort { |h1, h2| h2[:runtime] <=> h1[:runtime] }[0, 25]
    end

    def explain(sql, binds)
      rows = ActiveRecord::Base.connection.exec_query("EXPLAIN " + sql, "EXPLAIN", binds)
      rows.map { |row| row["QUERY PLAN"] }.join("\n")
    rescue => ex
    end

    def post_request
      post("/requests", request: request.merge(queries: slowest_queries, views: slowest_views, error: error))
    rescue => exception
      log_error(exception)
    end

    def extract_file_and_line_from_call_stack(stack)
      return unless location = stack.find { |str| str.include?(Rails.root.to_s) }
      file, line, method = location.split(":")
      method = cleanup_method_name(method)
      file.sub!(Rails.root.to_s, "")
      [file, line, method]
    end

    def cleanup_method_name(method)
      method.sub!("block in ", "")
      method.sub!("in `", "")
      method.sub!("'", "")
      method.index("_app_views_") == 0 ? nil : method
    end

    def compute_duration(start, finish)
      ((finish - start) * 1000)
    end

    def relative_path(path)
      path.sub(Rails.root.to_s, "")
    end

    def post(path, data)
      uri = URI(api_url + path)
      Net::HTTP.start(uri.host, uri.port) do |http|
        post = Net::HTTP::Post.new(uri.path)
        post.content_type = "application/json"
        post.basic_auth(app_id, api_key)
        post.body = data.to_json
        http.request(post)
      end
    end

    def params_filter
      @params_filter ||= ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
    end

    def logger
      Rails.logger
    end

    def log_error(exception)
      logger.error("[RorVsWild] " + exception.inspect)
      logger.error("[RorVsWild] " + exception.backtrace.join("\n[RorVsWild] "))
    end
  end
end
