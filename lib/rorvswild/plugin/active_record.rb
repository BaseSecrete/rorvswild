# frozen_string_literal: true

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

      def start(name, id, payload)
        return if IGNORED_QUERIES.include?(payload[:name])
        RorVsWild::Section.start do |section|
          section.commands << normalize_sql_query(payload[:sql])
          section.kind = "sql"
        end
      end

      def finish(name, id, payload)
        return if IGNORED_QUERIES.include?(payload[:name])
        RorVsWild::Section.stop
      end

      # Async queries
      def publish_event(event)
        section = Section.new
        section.total_ms = event.payload[:lock_wait]
        section.gc_time_ms = event.gc_time
        section.commands << normalize_sql_query(event.payload[:sql])
        section.async_ms = event.duration - event.payload[:lock_wait]
        section.kind = "sql"
        RorVsWild.agent.add_section(section)
      end

      SQL_STRING_REGEX = /'((?:''|\\'|[^'])*)'/
      SQL_NUMERIC_REGEX = /(?<!\w)\d+(\.\d+)?(?!\w)/
      SQL_PARAMETER_REGEX = /\$\d+/
      SQL_IN_REGEX = /(\bIN\s*\()([^)]+)(\))/i
      SQL_ONE_LINE_COMMENT_REGEX =/--.*$/
      SQL_MULTI_LINE_COMMENT_REGEX = /\/\*.*?\*\//m

      def normalize_sql_query(sql)
        sql = sql.to_s.gsub(SQL_STRING_REGEX, "?")
        sql.gsub!(SQL_PARAMETER_REGEX, "?")
        sql.gsub!(SQL_NUMERIC_REGEX, "?")
        sql.gsub!(SQL_IN_REGEX, '\1?\3')
        sql.gsub!(SQL_ONE_LINE_COMMENT_REGEX, "")
        sql.gsub!(SQL_MULTI_LINE_COMMENT_REGEX, "")
        sql.strip!
        sql
      end
    end
  end
end
