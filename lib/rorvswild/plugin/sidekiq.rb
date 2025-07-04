module RorVsWild
  module Plugin
    class Sidekiq
      def self.setup
        if defined?(::Sidekiq)
          ::Sidekiq.configure_server do |config|
            config.server_middleware { |chain| chain.add(Sidekiq) }
          end
        end
      end

      def call(worker, item, queue, &block)
        # Wrapped contains the real class name of the ActiveJob wrapper
        name = item["wrapped".freeze] || item["class".freeze]
        RorVsWild.agent.measure_job(name, parameters: item["args".freeze]) do
          section = RorVsWild::Section.start
          section.commands << "#{name}#perform"
          if perform_method = worker.method(:perform)
            section.file, section.line = worker.method(:perform).source_location
            section.file = RorVsWild.agent.locator.relative_path(section.file)
          end
          block.call
          RorVsWild::Section.stop
        end
      end
    end
  end
end
