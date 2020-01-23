module RorVsWild
  module Plugin
    class Faktory
      def self.setup
        if defined?(::Faktory)
          ::Faktory.configure_worker do |config|
            config.worker_middleware { |chain| chain.add(Faktory) }
          end
        end
      end

      def call(worker_instance, job, &block)
        custom = job["custom".freeze]
        name = (custom && custom["wrapped".freeze]) || job["jobtype".freeze]
        RorVsWild.agent.measure_job(name, parameters: job["args".freeze], &block)
      end
    end
  end
end
