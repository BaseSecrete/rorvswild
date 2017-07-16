require "logger"

module RorVsWild
  class Agent
    include RorVsWild::Location

    def self.default_config
      {
        api_url: "https://www.rorvswild.com/api",
        ignored_exceptions: [],
      }
    end

    attr_reader :api_url, :api_key, :app_id, :app_root, :ignored_exceptions

    attr_reader :app_root_regex, :client

    def initialize(config)
      config = self.class.default_config.merge(config)
      @ignored_exceptions = config[:ignored_exceptions]
      @app_root = config[:app_root]
      @logger = config[:logger]
      @client = Client.new(config)
      cleanup_data

      if defined?(Rails)
        @logger ||= Rails.logger
        @app_root ||= Rails.root.to_s
        config = Rails.application.config
        @ignored_exceptions ||= %w[ActionController::RoutingError] + config.action_dispatch.rescue_responses.map { |(key,value)| key }
      end

      @logger ||= Logger.new(STDERR)
      @app_root_regex = app_root ? /\A#{app_root}/ : nil

      setup_plugins
    end

    def setup_plugins
      Plugin::NetHttp.setup

      Plugin::Redis.setup
      Plugin::Mongo.setup

      Plugin::Resque.setup
      Plugin::Sidekiq.setup
      Plugin::ActiveJob.setup
      Plugin::DelayedJob.setup

      Plugin::ActionView.setup
      Plugin::ActiveRecord.setup
      Plugin::ActionMailer.setup
      Plugin::ActionController.setup
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
      return block.call if data[:name] # Prevent from recursive jobs
      initialize_data(name)
      begin
        block.call
      rescue Exception => ex
        push_exception(ex, parameters: parameters)
        raise
      ensure
        data[:runtime] = (Time.now - data[:started_at]) * 1000
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
      data[:runtime] = (Time.now.utc - data[:started_at]) * 1000
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

    #######################
    ### Private methods ###
    #######################

    private

    def initialize_data(name)
      data[:name] = name
      data[:sections] = []
      data[:section_stack] = []
      data[:started_at] = Time.now.utc
    end

    def cleanup_data
      result = Thread.current[:rorvswild_data]
      Thread.current[:rorvswild_data] = nil
      result
    end

    def post_request
      client.post_async("/requests".freeze, request: cleanup_data)
    end

    def post_job
      client.post_async("/jobs".freeze, job: cleanup_data)
    end

    def post_error(hash)
      client.post_async("/errors".freeze, error: hash)
    end

    def exception_to_hash(exception, extra_details = nil)
      file, line = extract_most_relevant_file_and_line_from_exception(exception)
      {
        line: line.to_i,
        file: relative_path(file),
        message: exception.message,
        backtrace: exception.backtrace || ["No backtrace"],
        exception: exception.class.to_s,
        extra_details: extra_details,
      }
    end

    def ignored_exception?(exception)
      ignored_exceptions.include?(exception.class.to_s)
    end
  end
end
