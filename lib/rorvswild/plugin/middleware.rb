# frozen_string_literal: true

module RorVsWild
  module Plugin
    class Middleware
      module RequestQueueTime

        ACCEPTABLE_HEADERS = [
          'HTTP_X_REQUEST_START',
          'HTTP_X_QUEUE_START',
          'HTTP_X_MIDDLEWARE_START'
        ].freeze

        MINIMUM_TIMESTAMP = 1577836800.freeze # 2020/01/01 UTC
        DIVISORS = [1_000_000, 1_000, 1].freeze

        def parse_queue_time_header(env)
          return unless env

          earliest = nil

          ACCEPTABLE_HEADERS.each do |header|
            if (header_value = env[header])
              timestamp = parse_timestamp(header_value.delete_prefix("t="))
              if timestamp && (!earliest || timestamp < earliest)
                earliest = timestamp
              end
            end
          end

          [earliest, Time.now.to_f].min if earliest
        end

        private

        def parse_timestamp(timestamp)
          timestamp = timestamp.to_f
          return unless timestamp.finite?

          DIVISORS.each do |divisor|
            t = timestamp / divisor
            return t if t > MINIMUM_TIMESTAMP
          end
        end
      end

      include RequestQueueTime

      def self.setup
        return if @installed
        Rails.application.config.middleware.unshift(RorVsWild::Plugin::Middleware, nil) if defined?(Rails)
        @installed = true
      end

      def initialize(app, config)
        @app, @config = app, config
      end

      def call(env)
        queue_time_ms = calculate_queue_time(env)
        RorVsWild.agent.start_request(queue_time_ms || 0)
        RorVsWild.agent.current_data[:path] = env["ORIGINAL_FULLPATH"]
        add_queue_time_section(queue_time_ms)
        section = RorVsWild::Section.start
        section.file, section.line = rails_engine_location
        section.commands << "Rails::Engine#call"
        code, headers, body = @app.call(env)
        [code, headers, body]
      ensure
        RorVsWild::Section.stop
        RorVsWild.agent.stop_request
      end

      private

      def add_queue_time_section(queue_time_ms)
        return unless queue_time_ms

        section = Section.new
        section.stop
        section.total_ms = queue_time_ms
        section.gc_time_ms = 0
        section.file = "request-queue"
        section.line = 0
        section.kind = "queue"
        RorVsWild.agent.add_section(section)
      end

      def calculate_queue_time(env)
        queue_time_from_header = parse_queue_time_header(env)

        ((Time.now.to_f - queue_time_from_header) * 1000).round if queue_time_from_header
      end

      def rails_engine_location
        @rails_engine_location = ::Rails::Engine.instance_method(:call).source_location
      end
    end
  end
end
