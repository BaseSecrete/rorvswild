module RorVsWild
  module Plugin
    class ActionMailer
      @installed = false

      def self.setup(agent)
        return if @installed
        return unless defined?(ActiveSupport::Notifications.subscribe)
        ActiveSupport::Notifications.subscribe("deliver.action_mailer", new)
        @installed = true
      end

      def start(name, id, payload)
        RorVsWild::Section.start
      end

      def finish(name, id, payload)
        RorVsWild::Section.stop do |section|
          section.commands << payload[:mailer]
          section.kind = "mail".freeze
        end
      end
    end
  end
end
