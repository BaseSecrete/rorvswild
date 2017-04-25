module RorVsWild
  module Plugin
    class ActiveRecord
      def self.setup
        return if @installed
        setup_callback
        @installed = true
      end

      def self.setup_callback
        return unless defined?(::ActiveSupport::Notifications.subscribe)
        ActiveSupport::Notifications.subscribe("sql.active_record", new)
      end

      IGNORED_QUERIES = %w[EXPLAIN SCHEMA].freeze
      APPENDABLE_QUERIES = ["BEGIN", "COMMIT"].freeze

      def start(name, id, payload)
        return if IGNORED_QUERIES.include?(payload[:name])
        RorVsWild::Section.start do |section|
          section.appendable_command = APPENDABLE_QUERIES.include?(payload[:sql])
          section.command = payload[:sql]
          section.kind = "sql".freeze
        end
      end

      def finish(name, id, payload)
        return if IGNORED_QUERIES.include?(payload[:name])
        RorVsWild::Section.stop
      end
    end
  end
end
