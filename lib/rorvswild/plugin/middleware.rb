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
        RorVsWild.agent.current_data[:path] = env["ORIGINAL_FULLPATH".freeze]
        section = RorVsWild::Section.start
        section.file, section.line = rails_engine_location
        section.command = "Rails::Engine#call".freeze
        @app.call(env)
      ensure
        RorVsWild::Section.stop
        RorVsWild.agent.stop_request
      end

      def rails_engine_location
        @rails_engine_location = ::Rails::Engine.instance_method(:call).source_location
      end
    end
  end
end
