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
      if defined?(ActionDispatch::ExceptionWrapper)
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
      Host.load_config(config)
      Deployment.load_config(config)

      RorVsWild.logger.debug("Start RorVsWild #{RorVsWild::VERSION}")
      setup_plugins
      cleanup_data
    end

    def load_features
      features = config[:features] || []
      RorVsWild.logger.info("Server metrics are now monitored enabled by default") if features.include?("server_metrics")
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
      current_execution ? measure_section(name, kind: kind, &block) : measure_job(name, &block)
    end

    def measure_method(method)
      return if method.name.end_with?("_measured_by_rorvswild")
      if method.is_a?(Method)
        method_full_name = [method.receiver, method.name].join(".") # Method => class method
      else
        method_full_name = [method.owner, method.name].join("#") # UnboundMethod => instance method
      end
      method_alias = :"#{method.name}_measured_by_rorvswild"
      return if method.owner.method_defined?(method_alias)
      method.owner.alias_method(method_alias, method.name)
      method_file, method_line = method.source_location
      method_file = locator.relative_path(File.expand_path(method_file))
      method.owner.define_method(method.name) do |*args|
        section = Section.start
        section.file = method_file
        section.line = method_line
        section.commands << method_full_name
        result = send(method_alias, *args)
        Section.stop
        result
      end
    end

    def measure_section(name, kind: "code", &block)
      return block.call unless current_execution
      begin
        RorVsWild::Section.start do |section|
          section.commands << name
          section.kind = kind
        end
        block.call
      ensure
        RorVsWild::Section.stop
      end
    end

    def measure_job(name, parameters: nil, &block)
      return measure_section(name, &block) if current_execution # For recursive jobs
      return block.call if ignored_job?(name)
      start_execution(Execution::Job.new(name, parameters))
      begin
        block.call
      rescue Exception => ex
        current_execution.add_exception(ex)
        raise
      ensure
        stop_execution
      end
    end

    def start_execution(execution)
      Thread.current[:rorvswild_execution] ||= execution
    end

    def stop_execution
      return unless execution = current_execution
      execution.stop
      case execution
      when Execution::Job then queue_job
      when Execution::Request then queue_request
      end
    end

    def catch_error(context = nil, &block)
      begin
        block.call
      rescue Exception => ex
        record_error(ex, context)
        ex
      end
    end

    def record_error(exception, context = nil)
      if !ignored_exception?(exception) && current_execution&.error&.exception != exception
        queue_error(Error.new(exception, context).as_json)
      end
    end

    def merge_error_context(hash)
      current_execution && current_execution.merge_error_context(hash)
    end

    def current_data
      Thread.current[:rorvswild_data]
    end

    def current_execution
      Thread.current[:rorvswild_execution]
    end

    def ignored_request?(name)
      config[:ignore_requests].any? { |str_or_regex| str_or_regex === name }
    end

    def ignored_job?(name)
      config[:ignore_jobs].any? { |str_or_regex| str_or_regex === name }
    end

    def ignored_exception?(exception)
      return false unless config[:ignore_exceptions]
      class_name = exception.class.to_s
      config[:ignore_exceptions].any? { |str_or_regex| str_or_regex === class_name }
    end

    #######################
    ### Private methods ###
    #######################

    private

    def cleanup_data
      result = Thread.current[:rorvswild_execution]
      Thread.current[:rorvswild_execution] = nil
      result
    end

    def queue_request
      if (execution = cleanup_data) && execution.name
        queue.push_request(execution.as_json)
      end
    end

    def queue_job
      queue.push_job(cleanup_data.as_json)
    end

    def queue_error(hash)
      queue.push_error(hash)
    end
  end
end
