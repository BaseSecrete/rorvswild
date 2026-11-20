# frozen_string_literal: true

module RorVsWild
  module Plugin
    class Sidekiq
      INTERNAL_EXCEPTIONS = ["Sidekiq::JobRetry::Handled", "Sidekiq::JobRetry::Skip"]

      def self.setup(agent)
        if defined?(::Sidekiq)
          ::Sidekiq.configure_server do |config|
            config.server_middleware { |chain| chain.add(Sidekiq) }
          end
          # Prevent RailsError plugin from sending internal Sidekiq exceptions captured by ActiveSupport::ErrorReporter.
          agent.config[:ignore_exceptions].concat(INTERNAL_EXCEPTIONS)
        end
      end

      # Sidekiq sets retry_count to 0 on the first failure, so the first retry is attempt 2.
      # An ActiveJob retried by retry_on is a new Sidekiq job which counts its previous executions.
      def self.attempt(item)
        attempt = item["retry_count".freeze] ? item["retry_count".freeze].to_i + 2 : 1
        if item["wrapped".freeze] && (job_data = item["args".freeze]&.first).is_a?(Hash)
          attempt += job_data["executions".freeze].to_i
        end
        attempt
      end

      def call(worker, item, queue, &block)
        # Wrapped contains the real class name of the ActiveJob wrapper
        name = item["wrapped".freeze] || item["class".freeze]
        RorVsWild.agent.measure_job(name, parameters: item["args".freeze], attempt: self.class.attempt(item)) do
          RorVsWild::Section.measure do |section|
            section.commands << "#{name}#perform"
            if perform_method = worker.method(:perform)
              section.file, section.line = worker.method(:perform).source_location
              section.file = RorVsWild.agent.locator.relative_path(section.file)
            end
            block.call
          end
        end
      end
    end
  end
end
