# frozen_string_literal: true

module RorVsWild
  module Plugin
    class Middleware
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
        max_time = sections.map(&:self_runtime).max
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
        sections = sections.sort_by(&:self_runtime).reverse[0,10]
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
