# frozen_string_literal: true

module RorVsWild
  module Plugin
    class ViewComponent
      @installed = false

      def self.setup(agent)
        return if @installed
        return if !defined?(::ViewComponent)
        return if !defined?(ActiveSupport::Notifications.subscribe)
        ActiveSupport::Notifications.subscribe("render.view_component", plugin = new)
        ActiveSupport::Notifications.subscribe("!render.view_component", plugin) # Before 3.4.0 (231d4bb72ce5df334fca6f3be4ed33e887bd2cc8)
        @installed = true
      end

      def start(name, id, payload)
        return if !payload[:identifier]
        RorVsWild::Section.start
      end

      def finish(name, id, payload)
        return if !payload[:identifier]
        RorVsWild::Section.stop do |section|
          section.kind = "view"
          section.commands << payload[:name]
          section.file = RorVsWild.agent.locator.relative_path(payload[:identifier])
          section.line = 0
        end
      end
    end
  end
end
