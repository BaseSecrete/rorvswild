# frozen_string_literal: true

module RorVsWild
  module Plugin
    class ActionView
      @installed = false

      def self.setup
        return if @installed
        return unless defined?(ActiveSupport::Notifications.subscribe)
        ActiveSupport::Notifications.subscribe("render_partial.action_view", plugin = new)
        ActiveSupport::Notifications.subscribe("render_template.action_view", plugin)
        ActiveSupport::Notifications.subscribe("render_collection.action_view", plugin)
        @installed = true
      end

      def start(name, id, payload)
        return if !payload[:identifier]
        return if payload[:count] == 0 # render empty collection
        RorVsWild::Section.start
      end

      def finish(name, id, payload)
        return if !payload[:identifier]
        return if payload[:count] == 0 # render empty collection
        RorVsWild::Section.stop do |section|
          section.kind = "view"
          section.commands << RorVsWild.agent.locator.relative_path(payload[:identifier])
          section.file = section.command
          section.line = 0
          section.calls = payload[:count] if payload[:count] # render collection
        end
      end
    end
  end
end
