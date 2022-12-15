require "logger"
require "socket"
require "etc"

module RorVsWild
  class Agent
    def self.default_config
      {
        api_url: "https://www.rorvswild.com/api/v1",
        ignore_exceptions: default_ignored_exceptions,
        ignore_requests: [],
        ignore_plugins: [],
        ignore_jobs: [],
      }
    end

    def self.default_ignored_exceptions
      if defined?(Rails)
        ActionDispatch::ExceptionWrapper.rescue_responses.keys
      else
        []
      end
    end

    attr_reader :config, :locator, :client, :queue

    def initialize(config)
      @config = self.class.default_config.merge(config)
      load_features
      @client = Client.new(@config)
      @queue = config[:queue] || Queue.new(client)
      @locator = RorVsWild::Locator.new

      RorVsWild.logger.debug("Start RorVsWild #{RorVsWild::VERSION}")
      setup_plugins
      cleanup_data
    end

    def load_features
      features = config[:features] || []
      features.include?("server_metrics")
      require "rorvswild/metrics" if features.include?("server_metrics")
    end

    def setup_plugins
      for name in RorVsWild::Plugin.constants
        next if config[:ignore_plugins] && config[:ignore_plugins].include?(name.to_s)
        if (plugin = RorVsWild::Plugin.const_get(name)).respond_to?(:setup)
          RorVsWild.logger.debug("Setup RorVsWild::Plugin::#{name}")
          plugin.setup
        end
      end
    end

    def measure_code(code)
      measure_block(code) { eval(code) }
    end

    def measure_block(name = nil, kind = "code".freeze, &block)
      current_data ? measure_section(name, kind: kind, &block) : measure_job(name, &block)
    end

    def measure_section(name, kind: "code", appendable_command: false, &block)
      return block.call unless current_data
      begin
        RorVsWild::Section.start do |section|
          section.appendable_command = appendable_command
          section.command = name
          section.kind = kind
        end
        block.call
      ensure
        RorVsWild::Section.stop
      end
    end

    def measure_job(name, parameters: nil, &block)
      return measure_section(name, &block) if current_data # For recursive jobs
      return block.call if ignored_job?(name)
      initialize_data[:name] = name
      begin
        block.call
      rescue Exception => ex
        push_exception(ex, parameters: parameters, job: {name: name})
        raise
      ensure
        current_data[:runtime] = RorVsWild.clock_milliseconds - current_data[:started_at]
        post_job
      end
    end

    def start_request
      current_data || initialize_data
    end

    def stop_request
      return unless current_data
      current_data[:runtime] = RorVsWild.clock_milliseconds - current_data[:started_at]
      post_request
    end

    def catch_error(extra_details = nil, &block)
      begin
        block.call
      rescue Exception => ex
        record_error(ex, extra_details) if !ignored_exception?(ex)
        ex
      end
    end

    def record_error(exception, extra_details = nil)
      post_error(exception_to_hash(exception, extra_details))
    end

    def push_exception(exception, options = nil)
      return if ignored_exception?(exception)
      return unless current_data
      current_data[:error] = exception_to_hash(exception)
      current_data[:error].merge!(options) if options
      current_data[:error]
    end

    def merge_error_context(hash)
      self.error_context = error_context ? error_context.merge(hash) : hash
    end

    def error_context
      current_data[:error_context] if current_data
    end

    def error_context=(hash)
      current_data[:error_context] = hash if current_data
    end

    def current_data
      Thread.current[:rorvswild_data]
    end

    def add_section(section)
      return unless current_data[:sections]
      if sibling = current_data[:sections].find { |s| s.sibling?(section) }
        sibling.merge(section)
      else
        current_data[:sections] << section
      end
    end

    def ignored_request?(name)
      (config[:ignore_actions] || config[:ignore_requests]).include?(name)
    end

    def ignored_job?(name)
      config[:ignore_jobs].include?(name)
    end

    def send_deployment
      params = Host.to_h.slice(:revision, :ruby, :rails)
      params[:description] = Host.revision_description
      response = client.post("/deployments", deployment: params)
    end

    #######################
    ### Private methods ###
    #######################

    private

    def initialize_data
      Thread.current[:rorvswild_data] = {
        sections: [],
        section_stack: [],
        environment: Host.to_h,
        started_at: RorVsWild.clock_milliseconds,
      }
    end

    def cleanup_data
      result = Thread.current[:rorvswild_data]
      Thread.current[:rorvswild_data] = nil
      result
    end

    def post_request
      (data = cleanup_data) && data[:name] && queue.push_request(data)
    end

    def post_job
      queue.push_job(cleanup_data)
    end

    def post_error(hash)
      client.post_async("/errors".freeze, error: hash)
    end

    def exception_to_hash(exception, context = nil)
      file, line = locator.find_most_relevant_file_and_line_from_exception(exception)
      context = context ? error_context.merge(context) : error_context if error_context
      {
        line: line.to_i,
        file: locator.relative_path(file),
        message: exception.message,
        backtrace: exception.backtrace || ["No backtrace"],
        exception: exception.class.to_s,
        extra_details: context,
        environment: Host.to_h,
      }
    end

    def ignored_exception?(exception)
      (config[:ignored_exceptions] || config[:ignore_exceptions]).include?(exception.class.to_s)
    end
  end
end
