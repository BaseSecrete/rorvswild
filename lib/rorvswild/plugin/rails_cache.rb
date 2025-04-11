# frozen_string_literal: true

module RorVsWild
  module Plugin
    class RailsCache
      def self.setup
        return if @installed
        return unless defined?(ActiveSupport::Notifications.subscribe)
        plugin = new
        for name in ["write", "read", "delete", "write_multi", "read_multi", "delete_multi", "increment", "decrement"]
          ActiveSupport::Notifications.subscribe("cache_#{name}.active_support", plugin)
        end
        @installed = true
      end

      def start(name, id, payload)
        RorVsWild::Section.start do |section|
          section.commands << name.split(".")[0].delete_prefix("cache_")
          section.kind = "cache"
        end
      end

      def finish(name, id, payload)
        RorVsWild::Section.stop
      end
    end
  end
end
