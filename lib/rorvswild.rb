require "rorvswild/version"

module RorVsWild
  def self.new(*args)
    warn "WARNING: RorVsWild.new is deprecated. Use RorVsWild::Client.new instead."
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
      ActiveSupport::Notifications.subscribe("sql.active_record", &method(:after_sql_query))
      ActiveSupport::Notifications.subscribe("render_template.action_view", &method(:after_view_rendering))
      ActiveSupport::Notifications.subscribe("process_action.action_controller", &method(:after_http_request))
      ActiveSupport::Notifications.subscribe("start_processing.action_controller", &method(:before_http_request))

      client = self
      ActionController::Base.rescue_from(StandardError) { |exception| client.after_exception(exception, self) }
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
      error[:parameters] = filter_sensitive_data(payload[:params]) if error
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
      push_query(file: file, line: line, method: method, sql: sql, plan: plan, runtime: runtime, times: 1)
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

    def after_exception(exception, controller)
      if !exception.is_a?(ActionController::RoutingError)
        file, line = exception.backtrace.first.split(":")
        @error = {
          line: line.to_i,
          file: relative_path(file),
          message: exception.message,
          backtrace: exception.backtrace,
          exception: exception.class.to_s,
          session: controller.session.to_hash,
          environment_variables: filter_sensitive_data(filter_environment_variables(controller.request.env))
        }
      end
      raise exception
    end

    def measure_job(code)
      @queries = []
      @job = {name: code}
      started_at = Time.now
      cpu_time_offset = cpu_time
      eval(code)
    rescue => exception
      file, line = exception.backtrace.first.split(":")
      job[:error] = {
        line: line.to_i,
        file: relative_path(file),
        message: exception.message,
        backtrace: exception.backtrace,
        exception: exception.class.to_s,
      }
      raise
    ensure
      job[:runtime] = Time.now - started_at
      job[:cpu_runtime] = cpu_time -  cpu_time_offset
      Thread.new { post_job }
    end

    def cpu_time
      time = Process.times
      time.utime + time.stime + time.cutime + time.cstime
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

    def job
      @job
    end

    def push_query(query)
      if query[:sql] || query[:plan]
        queries << query
      else
        if hash = queries.find { |hash| hash[:line] == query[:line] && hash[:file] == query[:file] }
          hash[:runtime] += query[:runtime]
          hash[:times] += 1
        else
          queries << query
        end
      end
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

    def post_job
      post("/jobs", job: job.merge(queries: slowest_queries))
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

    def filter_sensitive_data(hash)
      @sensitive_filter ||= ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
      @sensitive_filter.filter(hash)
    end

    def filter_environment_variables(hash)
      hash.clone.keep_if { |key,value| key == key.upcase }
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
