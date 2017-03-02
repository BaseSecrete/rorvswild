module RorVsWild
  module Plugin
    class ActionController
      def self.setup
        return if @installed
        return unless defined?(::ActiveSupport::Notifications.subscribe)
        ActiveSupport::Notifications.subscribe("process_action.action_controller", new)
        @installed = true
      end

      # Payload: controller, action, params, format, method, path
      def start(name, id, payload)
        payload = payload.merge(name: "#{payload[:controller]}##{payload[:action]}")
        RorVsWild.client.start_request(payload)
      end

      def finish(name, id, payload)
        RorVsWild::client.stop_request
      end
    end
  end
end
