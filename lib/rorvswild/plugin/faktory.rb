# frozen_string_literal: true

module RorVsWild
  module Plugin
    class Faktory
      def self.setup(agent)
        if defined?(::Faktory)
          ::Faktory.configure_worker do |config|
            config.worker_middleware { |chain| chain.add(Faktory) }
          end
        end
      end

      def call(worker_instance, job, &block)
        custom = job["custom".freeze]
        name = (custom && custom["wrapped"]) || job["jobtype"]
        # Faktory omits failure on the first run, then sets failure.retry_count to 0 on the first retry.
        attempt = (failure = job["failure"]) ? failure["retry_count"].to_i + 2 : 1
        RorVsWild.agent.measure_job(name, parameters: job["args"], attempt: attempt, &block)
      end
    end
  end
end
