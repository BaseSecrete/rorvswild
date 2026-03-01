# frozen_string_literal: true

module RorVsWild
  module Plugin
    class Rack
      @installed = false

      def self.setup(agent)
        return if @installed
        return if !defined?(ActiveSupport::Notifications.subscribe)
        ActiveSupport::Notifications.subscribe("process_middleware.action_dispatch", new)
        @installed = true
      end

      def start(name, id, payload)
        section = RorVsWild::Section.start
        section.kind = "rack"
        if location = source_location(payload[:middleware])
          section.file = location[0]
          section.line = location[1]
          section.commands << payload[:middleware]
        else
          section.file = payload[:middleware]
          section.line = 0
        end
      end

      def finish(name, id, payload)
        RorVsWild::Section.stop
      end

      private

      def source_location(middleware_name)
        middleware = Kernel.const_get(middleware_name)
        middleware.instance_method(:call).source_location
      rescue NameError
      end
    end
  end
end
