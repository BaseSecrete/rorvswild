module RorVsWild
  module Plugin
    class ActionView
      def self.setup
        return if @installed
        return unless defined?(::ActiveSupport::Notifications.subscribe)
        ActiveSupport::Notifications.subscribe("render_partial.action_view", new)
        ActiveSupport::Notifications.subscribe("render_template.action_view", new)
        @installed = true
      end

      def start(name, id, payload)
        RorVsWild::Section.start
      end

      def finish(name, id, payload)
        RorVsWild::Section.stop do |section|
          section.kind = "view".freeze
          section.command = RorVsWild.agent.relative_path(payload[:identifier])
        end
      end
    end
  end
end
