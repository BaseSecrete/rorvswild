# frozen_string_literal: true

require "set"
require "uri"
require "zlib"
require "json/ext"
require "net/http"

module RorVsWild
  class Client
    HTTPS = "https".freeze
    CERTIFICATE_AUTHORITIES_PATH = File.expand_path("../../../cacert.pem", __FILE__)
    DEFAULT_TIMEOUT = 10

    attr_reader :api_url, :api_key, :timeout, :threads, :config

    def initialize(config)
      Kernel.at_exit(&method(:at_exit))
      @api_url = config[:api_url]
      @api_key = config[:api_key]
      @timeout ||= config[:timeout] || DEFAULT_TIMEOUT
      @threads = Set.new
      @connections = []
      @connection_count = 0
      @mutex = Mutex.new
      @config = config
      @headers = {
        "Content-Encoding" => "deflate",
        "Content-Type" => "application/json",
        "X-RorVsWild-Version" => RorVsWild::VERSION,
        "X-Ruby-Version" => RUBY_VERSION,
      }
      @headers["X-Rails-Version"] = Rails.version if defined?(Rails)
      @http_unauthorized = false
    end

    def post(path, data)
      uri = URI(api_url + path)
      post = Net::HTTP::Post.new(uri.path, @headers)
      post.basic_auth(nil, api_key)
      post.body = Zlib.deflate(JSON.generate(data), Zlib::BEST_SPEED)
      transmit(post)
    end

    def take_connection
      @mutex.synchronize { @connections.shift }
    end

    def release_connection(http)
      @mutex.synchronize { @connections.push(http) } if http
    end

    def max_connections
      @max_connections ||= [Process.getrlimit(Process::RLIMIT_NOFILE).first / 10, 10].max
    end

    def take_or_create_connection
      if http = take_connection
        http.start unless http.active?
        http
      elsif @connection_count < max_connections
        @connection_count += 1
        new_http
      end
    end

    def transmit(request)
      if !@http_unauthorized && http = take_or_create_connection
        response = http.request(request)
        @http_unauthorized = true if response.code == "401"
        response
      end
    rescue Exception => ex
      RorVsWild.logger.error(ex.full_message)
    ensure
      release_connection(http)
    end

    def new_http
      uri = URI(api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = timeout
      http.keep_alive_timeout = 5

      if uri.scheme == HTTPS
        # Disable peer verification while there is a memory leak with OpenSSL
        # http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        # http.ca_file = CERTIFICATE_AUTHORITIES_PATH
        http.use_ssl = true
      end

      http
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
  end
end
