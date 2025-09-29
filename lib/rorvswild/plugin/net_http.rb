module RorVsWild
  module Plugin
    class NetHttp
      HTTP = "http".freeze

      def self.setup(agent)
        return if !defined?(Net::HTTP)
        return if Net::HTTP.method_defined?(:request_without_rorvswild)

        Net::HTTP.class_eval do
          alias_method :request_without_rorvswild, :request

          def request(req, body = nil, &block)
            if Thread.current[:rorvswild_ignore_net_http]
              request_without_rorvswild(req, body, &block)
            else
              request_with_rorvswild(req, body, &block)
            end
          end

          def request_with_rorvswild(req, body = nil, &block)
            return request_without_rorvswild(req, body, &block) if !RorVsWild.agent || request_called_twice?
            RorVsWild.agent.measure_section("#{req.method} #{address}", kind: HTTP) do
              request_without_rorvswild(req, body, &block)
            end
          end

          def request_called_twice?
            # Net::HTTP#request calls itself when connection is not started.
            # This condition prevents from counting twice the request.
            (current_section = RorVsWild::Section.current) && current_section.kind == HTTP
          end
        end
      end

      def self.ignore(&block)
        old_value = Thread.current[:rorvswild_ignore_net_http]
        Thread.current[:rorvswild_ignore_net_http] = true
        block.call
      ensure
        Thread.current[:rorvswild_ignore_net_http] = old_value
      end
    end
  end
end
