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
        inject_server_timing(RorVsWild.agent.stop_request, headers)
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

      def format_server_timing_header(sections)
        sections.map do |section|
          if section.kind == "view"
            "#{section.kind};dur=#{section.self_ms.round};desc=\"#{section.file}\""
          else
            "#{section.kind};dur=#{section.self_ms.round};desc=\"#{section.file}:#{section.line}\""
          end
        end.join(", ")
      end

      def format_server_timing_ascii(sections, total_width = 80)
        max_time = sections.map(&:self_ms).max
        chart_width = (total_width * 0.25).to_i
        rows = sections.map { |section|
          [
            section.kind == "view" ? section.file : "#{section.file}:#{section.line}",
            "█" * (section.self_ms * (chart_width-1) / max_time),
            "%.1fms" % section.self_ms,
          ]
        }
        time_width = rows.map { |cols| cols[2].size }.max + 1
        label_width = total_width - chart_width - time_width
        rows.each { |cols| cols[0] = truncate_backwards(cols[0], label_width) }
        template = "%-#{label_width}s%#{chart_width}s%#{time_width}s"
        rows.map { |cols| format(template, *cols) }.join("\n")
      end

      def truncate_backwards(string, width)
        string.size > width ? "…" + string[-(width - 1)..-1] : string
      end

      def inject_server_timing(data, headers)
        return if !data || !data[:send_server_timing] || !(sections = data[:sections])
        sections = sections.sort_by(&:self_ms).reverse[0,10]
        headers["Server-Timing"] = format_server_timing_header(sections)
        if data[:name] && RorVsWild.logger.level <= Logger::Severity::DEBUG
          RorVsWild.logger.debug(["┤ #{data[:name]} ├".center(80, "─"),
            format_server_timing_ascii(sections),
            "─" * 80, nil].join("\n")
          )
        end
      end
    end
  end
end
