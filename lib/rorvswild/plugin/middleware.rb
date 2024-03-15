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
        section.command = "Rails::Engine#call"
        code, headers, body = @app.call(env)
        [code, headers, body]
      ensure
        RorVsWild::Section.stop
        inject_server_timing(RorVsWild.agent.stop_request, headers)
      end

      def rails_engine_location
        @rails_engine_location = ::Rails::Engine.instance_method(:call).source_location
      end

      def format_server_timing(sections)
        sections.sort_by(&:self_runtime).reverse.map do |section|
          if section.kind == "view"
            "#{section.kind};dur=#{section.self_runtime};desc=\"#{section.file}\""
          else
            "#{section.kind};dur=#{section.self_runtime};desc=\"#{section.file}:#{section.line}\""
          end
        end.join(", ")
      end

      def inject_server_timing(data, headers)
        return if !data || !data[:send_server_timing] || !(sections = data[:sections])
        headers["Server-Timing"] = format_server_timing(sections)
      end
    end
  end
end
