module RorVsWild
  module Plugin
    class ActionController
      def self.setup
        return if @installed
        return unless defined?(::ActionController::Base)
        ActiveSupport::Notifications.subscribe("process_action.action_controller", new)
        ::ActionController::Base.rescue_from(StandardError) do |exception|
          RorVsWild::Plugin::ActionController.after_exception(exception, self)
        end
        @installed = true
      end

      def self.after_exception(exception, controller)
        if hash = RorVsWild.client.push_exception(exception)
          hash[:session] = controller.session.to_hash
          hash[:environment_variables] = controller.request.filtered_env
        end
        raise exception
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
