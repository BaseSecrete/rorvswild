require "set"
require "uri"
require "net/http"
require "json/ext"

module RorVsWild
  class Client
    HTTPS = "https".freeze
    CERTIFICATE_AUTHORITIES_PATH = File.expand_path("../../../cacert.pem", __FILE__)
    DEFAULT_TIMEOUT = 1

    attr_reader :api_url, :api_key, :threads

    def initialize(config)
      Kernel.at_exit(&method(:at_exit))
      @api_url = config[:api_url]
      @api_key = config[:api_key]
      @threads = Set.new
    end

    def post(path, data)
      uri = URI(api_url + path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = config[:timeout] || DEFAULT_TIMEOUT

      if uri.scheme == HTTPS
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = CERTIFICATE_AUTHORITIES_PATH
        http.use_ssl = true
      end

      post = Net::HTTP::Post.new(uri.path, "X-Gem-Version".freeze => RorVsWild::VERSION)
      post.content_type = "application/json".freeze
      post.basic_auth(nil, api_key)
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
  end
end
