require "rorvswild/version"
require "json/ext"
require "net/http"
require "uri"

module RorVsWild
  def self.new(*args)
    warn "WARNING: RorVsWild.new is deprecated. Use RorVsWild::Client.new instead."
    Client.new(*args) # Compatibility with 0.0.1
  end

  def self.register_default_client(client)
    @default_client = client
  end

  def self.default_client
    @default_client
  end

  def self.measure_job(code)
    default_client ? default_client.measure_job(code) : eval(code)
  end

  def self.measure_code(code)
    default_client ? default_client.measure_code(code) : eval(code)
  end

  def self.measure_block(name, &block)
    default_client ? default_client.measure_block(name , &block) : block.call
  end

  def self.catch_error(extra_details = nil, &block)
    default_client ? default_client.catch_error(extra_details, &block) : block.call
  end

  def self.record_error(exception, extra_details = nil)
    default_client.record_error(exception, extra_details) if default_client
  end

  class Client
    def self.default_config
      {
        api_url: "http://www.rorvswild.com/api",
        explain_sql_threshold: 500,
        log_sql_threshold: 100,
      }
    end

    attr_reader :api_url, :api_key, :app_id, :explain_sql_threshold, :log_sql_threshold

    def initialize(config)
      config = self.class.default_config.merge(config)
      @explain_sql_threshold = config[:explain_sql_threshold]
      @log_sql_threshold = config[:log_sql_threshold]
      @api_url = config[:api_url]
      @api_key = config[:api_key]
      @app_id = config[:app_id]
      @data = {}
      setup_callbacks
      RorVsWild.register_default_client(self)
    end

    def setup_callbacks
      client = self
      if defined?(Rails)
        ActiveSupport::Notifications.subscribe("sql.active_record", &method(:after_sql_query))
        ActiveSupport::Notifications.subscribe("render_template.action_view", &method(:after_view_rendering))
        ActiveSupport::Notifications.subscribe("process_action.action_controller", &method(:after_http_request))
        ActiveSupport::Notifications.subscribe("start_processing.action_controller", &method(:before_http_request))
        ActionController::Base.rescue_from(StandardError) { |exception| client.after_exception(exception, self) }
      end

      Resque::Job.send(:extend, ResquePlugin) if defined?(Resque::Job)
      Delayed::Worker.lifecycle.around(:invoke_job, &method(:around_delayed_job)) if defined?(Delayed::Worker)
      Sidekiq.configure_server { |config| config.server_middleware { |chain| chain.add(SidekiqPlugin) } } if defined?(Sidekiq)
    end

    def before_http_request(name, start, finish, id, payload)
      request.merge!(controller: payload[:controller], action: payload[:action], path: payload[:path])
    end

    def after_http_request(name, start, finish, id, payload)
      request[:db_runtime] = (payload[:db_runtime] || 0).round
      request[:view_runtime] = (payload[:view_runtime] || 0).round
      request[:other_runtime] = compute_duration(start, finish) - request[:db_runtime] - request[:view_runtime]
      request[:error][:parameters] = filter_sensitive_data(payload[:params]) if request[:error]
      post_request
    rescue => exception
      log_error(exception)
    end

    def after_sql_query(name, start, finish, id, payload)
      return if !queries || payload[:name] == "EXPLAIN".freeze
      runtime, sql, plan = compute_duration(start, finish), nil, nil
      file, line, method = extract_most_relevant_location(caller)
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
        request[:error] = exception_to_hash(exception).merge(
          session: controller.session.to_hash,
          environment_variables: filter_sensitive_data(filter_environment_variables(controller.request.env))
        )
      end
      raise exception
    end

    def around_delayed_job(job, &block)
      measure_block(job.name) { block.call(job) }
    end

    def measure_job(code)
      warn "WARNING: RorVsWild.measure_job is deprecated. Use RorVsWild.measure_code instead."
      measure_block(code) { eval(code) }
    end

    def measure_code(code)
      measure_block(code) { eval(code) }
    end

    def measure_block(name, &block)
      job[:name] = name
      started_at = Time.now
      cpu_time_offset = cpu_time
      block.call
    rescue => exception
      job[:error] = exception_to_hash(exception)
      raise
    ensure
      job[:runtime] = (Time.now - started_at) * 1000
      job[:cpu_runtime] = (cpu_time -  cpu_time_offset) * 1000
      post_job
    end

    def catch_error(extra_details = nil, &block)
      begin
        block.call
      rescue => exception
        record_error(exception, extra_details)
        exception
      end
    end

    def record_error(exception, extra_details = nil)
      post_error(exception_to_hash(exception, extra_details))
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
      data[:queries] ||= []
    end

    def views
      data[:views] ||= {}
    end

    def job
      data
    end

    def request
      data
    end

    def data
      @data[Thread.current.object_id] ||= {}
    end

    def cleanup_data
      @data.delete(Thread.current.object_id)
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

    SELECT_REGEX = /\Aselect/i.freeze

    def explain(sql, binds)
      ActiveRecord::Base.connection.explain(sql, binds) if sql =~ SELECT_REGEX
    end

    def post_request
      attributes = request.merge(queries: slowest_queries, views: slowest_views)
      Thread.new { post("/requests".freeze, request: attributes) }
    ensure
      cleanup_data
    end

    def post_job
      post("/jobs".freeze, job: job.merge(queries: slowest_queries))
    rescue => exception
      log_error(exception)
    ensure
      cleanup_data
    end

    def post_error(hash)
      post("/errors".freeze, error: hash)
    end

    GEM_HOME_REGEX = ENV["GEM_HOME"] ? /\A#{ENV["GEM_HOME"]}/.freeze : nil

    def extract_most_relevant_location(stack)
      location = stack.find { |str| !(str =~ GEM_HOME_REGEX) } if GEM_HOME_REGEX
      split_file_location(relative_path(location || stack.first))
    end

    def split_file_location(location)
      file, line, method = location.split(":")
      method = cleanup_method_name(method) if method
      [file, line, method]
    end

    def cleanup_method_name(method)
      method.sub!("block in ".freeze, "".freeze)
      method.sub!("in `".freeze, "".freeze)
      method.sub!("'".freeze, "".freeze)
      method.index("_app_views_".freeze) == 0 ? nil : method
    end

    def compute_duration(start, finish)
      ((finish - start) * 1000)
    end

    def relative_path(path)
      defined?(Rails) ? path.sub(Rails.root.to_s, "".freeze) : path
    end

    def exception_to_hash(exception, extra_details = nil)
      file, line, method = extract_most_relevant_location(exception.backtrace)
      {
        method: method,
        line: line.to_i,
        file: relative_path(file),
        message: exception.message,
        backtrace: exception.backtrace,
        exception: exception.class.to_s,
        extra_details: extra_details,
      }
    end

    def post(path, data)
      uri = URI(api_url + path)
      Net::HTTP.start(uri.host, uri.port) do |http|
        post = Net::HTTP::Post.new(uri.path)
        post.content_type = "application/json".freeze
        post.basic_auth(app_id, api_key)
        post.body = data.to_json
        http.request(post)
      end
    end

    def filter_sensitive_data(hash)
      if defined?(Rails)
        @sensitive_filter ||= ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
        @sensitive_filter.filter(hash)
      else
        hash
      end
    end

    def filter_environment_variables(hash)
      hash.clone.keep_if { |key,value| key == key.upcase }
    end

    def log_error(exception)
      if defined?(Rails)
        Rails.logger.error("[RorVsWild] " + exception.inspect)
        Rails.logger.error("[RorVsWild] " + exception.backtrace.join("\n[RorVsWild] "))
      else
        $stderr.puts("[RorVsWild] " + exception.inspect)
        $stderr.puts("[RorVsWild] " + exception.backtrace.join("\n[RorVsWild] "))
      end
    end
  end

  DASH_PERFORM = "#perform".freeze

  module ResquePlugin
    def around_perform_rorvswild(*args, &block)
      RorVsWild.measure_block(to_s + DASH_PERFORM, &block)
    end
  end

  class SidekiqPlugin
    def call(worker, item, queue, &block)
      RorVsWild.measure_block(item["class".freeze] + DASH_PERFORM, &block)
    end
  end
end
