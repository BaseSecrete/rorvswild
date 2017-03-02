require "json/ext"
require "net/http"
require "logger"
require "uri"
require "set"

module RorVsWild
  class Client
    include RorVsWild::Location

    def self.default_config
      {
        api_url: "https://www.rorvswild.com/api",
        ignored_exceptions: [],
      }
    end

    attr_reader :api_url, :api_key, :app_id, :app_root, :ignored_exceptions

    attr_reader :threads, :app_root_regex

    def initialize(config)
      config = self.class.default_config.merge(config)
      @ignored_exceptions = config[:ignored_exceptions]
      @app_root = config[:app_root]
      @api_url = config[:api_url]
      @api_key = config[:api_key]
      @app_id = config[:app_id]
      @logger = config[:logger]
      @threads = Set.new
      @data = {}

      if defined?(Rails)
        @logger ||= Rails.logger
        @app_root ||= Rails.root.to_s
        config = Rails.application.config
        @parameter_filter = ActionDispatch::Http::ParameterFilter.new(config.filter_parameters)
        @ignored_exceptions ||= %w[ActionController::RoutingError] + config.action_dispatch.rescue_responses.map { |(key,value)| key }
      end

      @logger ||= Logger.new(STDERR)
      @app_root_regex = app_root ? /\A#{app_root}/ : nil

      setup_plugins
      RorVsWild.register_client(self)
      Kernel.at_exit(&method(:at_exit))
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
      Plugin::ActionController.setup
    end

    def measure_code(code)
      measure_block(code) { eval(code) }
    end

    def measure_block(name, kind = "code", &block)
      data[:name] ? measure_nested_block(name, kind, &block) : measure_root_block(name, &block)
    end

    def measure_nested_block(name, kind = "code", &block)
      RorVsWild::Section.start do |section|
        section.command = name
        section.kind = kind
      end
      block.call
    ensure
      RorVsWild::Section.stop
    end

    def measure_root_block(name, &block)
      return block.call if job[:name] # Prevent from recursive jobs
      job[:name] = name
      job[:queries] = []
      job[:sections] = []
      data[:section_stack] = []
      started_at = Time.now
      begin
        block.call
      rescue Exception => ex
        job[:error] = exception_to_hash(ex) if !ignored_exception?(ex)
        raise
      ensure
        job[:runtime] = (Time.now - started_at) * 1000
        post_job
      end
    end

    def start_request(payload)
      return if data[:name]
      data[:name] = payload[:name]
      data[:sections] = []
      data[:section_stack] = []
      data[:started_at] = Time.now.utc
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

    def push_section(section)
      data[:section_stack].push(section)
    end

    def push_exception(exception)
      return if ignored_exception?(exception)
      data[:error] = exception_to_hash(exception)
    end

    def data
      @data[Thread.current.object_id] ||= {}
    end

    def add_section(section)
      if sibling = sections.find { |s| s.sibling?(section) }
        sibling.merge(section)
      else
        sections << section
      end
    end

    #######################
    ### Private methods ###
    #######################

    private

    def sections
      data[:sections]
    end

    def job
      data
    end

    def request
      data
    end

    def pop_section
      data[:section_stack].pop
    end

    def last_section
      data[:section_stack].last
    end

    def cleanup_data
      @data.delete(Thread.current.object_id)
    end

    def post_request
      post_async("/requests".freeze, request: data)
    ensure
      cleanup_data
    end

    def post_job
      attributes = job.merge(sections: sections)
      post_async("/jobs".freeze, job: attributes)
    rescue => exception
      log_error(exception)
    ensure
      cleanup_data
    end

    def post_error(hash)
      post_async("/errors".freeze, error: hash)
    end

    def compute_duration(start, finish)
      ((finish - start) * 1000)
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

    HTTPS = "https".freeze
    CERTIFICATE_AUTHORITIES_PATH = File.expand_path("../../../cacert.pem", __FILE__)

    def post(path, data)
      uri = URI(api_url + path)
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == HTTPS
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = CERTIFICATE_AUTHORITIES_PATH
        http.use_ssl = true
      end

      post = Net::HTTP::Post.new(uri.path)
      post.content_type = "application/json".freeze
      post.basic_auth(app_id, api_key)
      post.body = data.to_json
      http.request(post)
    end

    def post_async(path, data)
      Thread.new do
        begin
          threads.add(Thread.current)
          post(path, data)
        ensure
          threads.delete(Thread.current)
        end
      end
    end

    def at_exit
      threads.each(&:join)
    end

    def ignored_exception?(exception)
      ignored_exceptions.include?(exception.class.to_s)
    end

    def log_error(exception)
      @logger.error("[RorVsWild] " + exception.inspect)
      @logger.error("[RorVsWild] " + exception.backtrace.join("\n[RorVsWild] "))
    end
  end
end
