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
        if RorVsWild.agent.send_server_timing?
          headers["Server-Timing"] = format_server_timing(Thread.current[:rorvswild_data][:sections])
        end
        [code, headers, body]
      ensure
        RorVsWild::Section.stop
        RorVsWild.agent.stop_request
      end

      def rails_engine_location
        @rails_engine_location = ::Rails::Engine.instance_method(:call).source_location
      end

      def format_server_timing(sections)
        sections.sort_by(&:self_runtime).reverse.map do |section|
          "#{section.kind};dur=#{section.self_runtime};desc=\"#{section.file}:#{section.line}\""
        end.join(", ")
      end
    end
  end
end
