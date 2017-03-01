module RorVsWild
  module Plugin
    class NetHttp
      def self.setup
        return if !defined?(Net::HTTP)
        return if Net::HTTP.method_defined?(:request_without_rorvswild)

        Net::HTTP.class_eval do
          alias_method :request_without_rorvswild, :request

          def request(req, body = nil, &block)
            scheme = use_ssl? ? "https".freeze : "http".freeze
            url = "#{req.method} #{scheme}://#{address}#{req.path}"
            RorVsWild.client.measure_block(url, "http".freeze) do
              request_without_rorvswild(req, body, &block)
            end
          end
        end
      end
    end
  end
end
