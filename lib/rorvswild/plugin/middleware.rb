# frozen_string_literal: true

module RorVsWild
  module Plugin
    class Middleware
      module RequestQueueTime
        REQUEST_START_HEADER = 'HTTP_X_REQUEST_START'.freeze
        QUEUE_START_HEADER = 'HTTP_X_QUEUE_START'.freeze
        MIDDLEWARE_START_HEADER = 'HTTP_X_MIDDLEWARE_START'.freeze

        ACCEPTABLE_HEADERS = [
          REQUEST_START_HEADER,
          QUEUE_START_HEADER,
          MIDDLEWARE_START_HEADER
        ].freeze

        MINIMUM_TIMESTAMP = 1577836800.freeze # 2020/01/01 UTC
        DIVISORS = [1_000_000, 1_000, 1].freeze

        def parse_queue_time_header(headers)
          return unless headers

          earliest = nil

          ACCEPTABLE_HEADERS.each do |header|
            next unless headers[header]

            timestamp = parse_timestamp(headers[header].gsub("t=", ""))
            if timestamp && (!earliest || timestamp < earliest)
              earliest = timestamp
            end
          end

          [earliest, Time.now.to_f].min if earliest
        end

        private

        def parse_timestamp(timestamp)
          DIVISORS.each do |divisor|
            begin
              t = (timestamp.to_f / divisor)
              return t if t > MINIMUM_TIMESTAMP
            rescue RangeError
            end
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
        RorVsWild.agent.start_request
        RorVsWild.agent.current_data[:path] = env["ORIGINAL_FULLPATH"]
        RorVsWild.agent.current_data[:queue_time] = calculate_queue_time(env)
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

      def calculate_queue_time(headers)
        queue_time_from_header = parse_queue_time_header(headers)

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
