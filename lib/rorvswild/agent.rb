require "logger"

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
        %w[ActionController::RoutingError] + Rails.application.config.action_dispatch.rescue_responses.map { |(key,value)| key }
      else
        []
      end
    end

    attr_reader :config, :locator, :client, :queue

    def initialize(config)
      @config = self.class.default_config.merge(config)
      @client = Client.new(@config)
      @queue = config[:queue] || Queue.new(client)
      @locator = RorVsWild::Locator.new(defined?(Rails) ? Rails.root.to_s : ENV["PWD"])

      RorVsWild.logger.info("Start RorVsWild #{RorVsWild::VERSION}")
      setup_plugins
      cleanup_data
    end

    def setup_plugins
      for name in RorVsWild::Plugin.constants
        next if config[:ignore_plugins] && config[:ignore_plugins].include?(name.to_s)
        if (plugin = RorVsWild::Plugin.const_get(name)).respond_to?(:setup)
          RorVsWild.logger.info("Load plugin #{name}")
          plugin.setup
        end
      end
    end

    def measure_code(code)
      measure_block(code) { eval(code) }
    end

    def measure_block(name, kind = "code".freeze, &block)
      data[:name] ? measure_section(name, kind: kind, &block) : measure_job(name, &block)
    end

    def measure_section(name, kind: "code", appendable_command: false, &block)
      return block.call unless data[:name]
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
      return measure_section(name, &block) if data[:name] # For recursive jobs
      return block.call if ignored_job?(name)
      initialize_data(name)
      begin
        block.call
      rescue Exception => ex
        push_exception(ex, parameters: parameters)
        raise
      ensure
        data[:runtime] = RorVsWild.clock_milliseconds - data[:started_at]
        post_job
      end
    end

    def start_request(payload)
      return if data[:name]
      initialize_data(payload[:name])
      data[:path] = payload[:path]
    end

    def stop_request
      return unless data[:name]
      data[:runtime] = RorVsWild.clock_milliseconds - data[:started_at]
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
      data[:error] = exception_to_hash(exception)
      data[:error].merge!(options) if options
      data[:error]
    end

    def data
      Thread.current[:rorvswild_data] ||= {}
    end

    def add_section(section)
      return unless data[:sections]
      if sibling = data[:sections].find { |s| s.sibling?(section) }
        sibling.merge(section)
      else
        data[:sections] << section
      end
    end

    def ignored_request?(name)
      (config[:ignore_actions] || config[:ignore_requests]).include?(name)
    end

    def ignored_job?(name)
      config[:ignore_jobs].include?(name)
    end

    #######################
    ### Private methods ###
    #######################

    private

    def initialize_data(name)
      data[:name] = name
      data[:sections] = []
      data[:section_stack] = []
      data[:started_at] = RorVsWild.clock_milliseconds
    end

    def cleanup_data
      result = Thread.current[:rorvswild_data]
      Thread.current[:rorvswild_data] = nil
      result
    end

    def post_request
      queue.push_request(cleanup_data)
    end

    def post_job
      queue.push_job(cleanup_data)
    end

    def post_error(hash)
      client.post_async("/errors".freeze, error: hash)
    end

    def exception_to_hash(exception, extra_details = nil)
      file, line = locator.find_most_relevant_file_and_line_from_exception(exception)
      {
        line: line.to_i,
        file: locator.relative_path(file),
        message: exception.message,
        backtrace: exception.backtrace || ["No backtrace"],
        exception: exception.class.to_s,
        extra_details: extra_details,
      }
    end

    def ignored_exception?(exception)
      (config[:ignored_exceptions] || config[:ignore_exceptions]).include?(exception.class.to_s)
    end
  end
end
