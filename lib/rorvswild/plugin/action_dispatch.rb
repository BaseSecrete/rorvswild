module RorVsWild
  module Plugin
    class ActionDispatch
      def self.setup
        return if @installed
        return unless defined?(::ActiveSupport::Notifications)
        ActiveSupport::Notifications.subscribe("request.action_dispatch", new)
        @installed = true
      end

      def start(name, id, payload)
        RorVsWild.agent.start_request
        RorVsWild.agent.current_data[:path] = payload[:request].original_fullpath
        @action_dispath_location ||= ::ActionDispatch::Executor.instance_method(:call).source_location
        section = RorVsWild::Section.start
        section.file, section.line = @action_dispath_location
        section.kind = "code".freeze
      end

      def finish(name, id, payload)
        RorVsWild::Section.stop
        RorVsWild.agent.stop_request
      end
    end
  end
end
