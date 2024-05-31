# frozen_string_literal: true

module RorVsWild
  module Plugin
    module DelayedJob
      def self.setup
        return if @installed
        return unless defined?(Delayed::Plugin)
        Delayed::Worker.plugins << Class.new(Delayed::Plugin) do
          callbacks do |lifecycle|
            lifecycle.around(:invoke_job) do |job, *args, &block|
              if job.payload_object.class.name == "ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper"
                job_name, job_args = job.payload_object.job_data.values_at("job_class", "arguments")
              elsif job.payload_object.is_a?(Delayed::PerformableMethod)
                job_name, job_args = job.name, job.payload_object.args
              else
                job_name, job_args = job.name, job.payload_object
              end
              RorVsWild.agent.measure_job(job_name, parameters: job_args) { block.call(job) }
            end
          end
        end
        @installed = true
      end
    end
  end
end
