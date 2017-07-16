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
        RorVsWild.agent.measure_job(name, parameters: item["args".freeze], &block)
      end
    end
  end
end
