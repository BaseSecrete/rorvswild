module RorVsWild
  module Plugin
    class Elasticsearch
      def self.setup
        return if !defined?(::Elasticsearch::Transport)
        return if ::Elasticsearch::Transport::Client.method_defined?(:perform_request_without_rorvswild)

        ::Elasticsearch::Transport::Client.class_eval do
          alias_method :perform_request_without_rorvswild, :perform_request

          def perform_request(*args)
            RorVsWild::Plugin::NetHttp.ignore do
              command = {method: args[0], path: args[1], params: args[2], body: args[3]}.to_json
              RorVsWild.agent.measure_section(command, kind: "elasticsearch") do
                perform_request_without_rorvswild(*args)
              end
            end
          end
        end
      end
    end
  end
end
