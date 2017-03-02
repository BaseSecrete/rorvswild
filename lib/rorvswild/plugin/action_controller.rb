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
        RorVsWild::Section.start do |section|
          section.command = "#{payload[:controller]}##{payload[:action]}"
          section.kind = "action_controller"
        end
      end

      def finish(name, id, payload)
        RorVsWild::Section.stop
      end
    end
  end
end
