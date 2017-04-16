module RorVsWild
  module Plugin
    class ActionController
      def self.setup
        return if @installed
        return unless defined?(::ActionController::Base)
        ActiveSupport::Notifications.subscribe("process_action.action_controller", new)
        ::ActionController::Base.after_action { RorVsWild::Plugin::ActionController.after_action(self) }
        ::ActionController::Base.before_action { RorVsWild::Plugin::ActionController.before_action(self) }
        ::ActionController::Base.rescue_from(StandardError) { |ex| RorVsWild::Plugin::ActionController.after_exception(ex, self) }
        @installed = true
      end

      def self.after_exception(exception, controller)
        if hash = RorVsWild.agent.push_exception(exception)
          hash[:session] = controller.session.to_hash
          hash[:environment_variables] = controller.request.filtered_env
        end
        raise exception
      end

      def self.before_action(controller)
        method_name = controller.method_for_action(controller.action_name)
        RorVsWild::Section.start do |section|
          section.file, section.line = controller.method(method_name).source_location
          section.command = "#{controller.class}##{method_name}"
          section.kind = "code".freeze
        end
      end

      def self.after_action(controller)
        RorVsWild::Section.stop
      end

      # Payload: controller, action, params, format, method, path
      def start(name, id, payload)
        name = "#{payload[:controller]}##{payload[:action]}"
        RorVsWild.agent.start_request(name: name, path: payload[:path])
      end

      def finish(name, id, payload)
        RorVsWild.agent.stop_request
      end
    end
  end
end
