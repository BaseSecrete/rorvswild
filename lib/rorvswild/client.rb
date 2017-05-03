require "set"
require "uri"
require "json/ext"
require "net/http"
require "net/http/persistent"

module RorVsWild
  class Client
    HTTPS = "https".freeze
    CERTIFICATE_AUTHORITIES_PATH = File.expand_path("../../../cacert.pem", __FILE__)
    DEFAULT_TIMEOUT = 1

    attr_reader :api_url, :api_key, :timeout, :threads

    def initialize(config)
      Kernel.at_exit(&method(:at_exit))
      @api_url = config[:api_url]
      @api_key = config[:api_key]
      @timeout ||= config[:timeout] || DEFAULT_TIMEOUT
      @threads = Set.new
    end

    def post(path, data)
      uri = URI(api_url + path)
      post = Net::HTTP::Post.new(uri.path, "X-Gem-Version".freeze => RorVsWild::VERSION)
      post.content_type = "application/json".freeze
      post.basic_auth(nil, api_key)
      post.body = data.to_json
      http.request(uri, post)
    end

    def http
      return @http if @http
      http = Net::HTTP::Persistent.new
      http.retry_change_requests = true
      http.open_timeout = timeout
      @http = http
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
