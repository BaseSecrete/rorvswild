module RorVsWild
  module Plugin
    class ActiveSupport
      def self.setup
        return if @installed
        setup_callback
        @installed = true
      end

      def self.setup_callback
        return unless defined?(::ActiveSupport::Notifications.subscribe)
        ActiveSupport::Notifications.subscribe("sql.active_record", &method(:after_sql_query))
      end

      IGNORED_QUERIES = %w[EXPLAIN SCHEMA].freeze

      def self.after_sql_query(name, start, finish, id, payload)
        return if IGNORED_QUERIES.include?(payload[:name])
        section = Section.new
        section.kind = "sql".freeze
        section.command = payload[:sql]
        section.runtime = (finish - start) * 1000
        section.file, section.line = RorVsWild.client.extract_most_relevant_location(caller)
        RorVsWild.client.send(:add_section, section)
      rescue => exception
        log_error(exception)
      end
    end
  end
end
