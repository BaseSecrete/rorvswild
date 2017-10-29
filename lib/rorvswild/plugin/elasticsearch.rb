module RorVsWild
  module Plugin
    class Elasticsearch
      def self.setup
        return if !defined?(::Elasticsearch::Transport)
        return if ::Elasticsearch::Transport::Client.method_defined?(:perform_request_without_rorvswild)

        ::Elasticsearch::Transport::Client.class_eval do
          alias_method :perform_request_without_rorvswild, :perform_request

          def perform_request(method, path, params={}, body=nil)
            RorVsWild::Plugin::NetHttp.ignore do
              command = {method: method, path: path, params: params, body: body}.to_json
              RorVsWild.agent.measure_section(command, kind: "elasticsearch") do
                perform_request_without_rorvswild(method, path, params, body)
              end
            end
          end
        end
      end
    end
  end
end
