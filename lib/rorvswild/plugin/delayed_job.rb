module RorVsWild
  module Plugin
    module DelayedJob
      def self.setup
        return if @installed
        return unless defined?(Delayed::Plugin)
        Delayed::Worker.plugins << Class.new(Delayed::Plugin) do
          callbacks do |lifecycle|
            lifecycle.around(:invoke_job) do |job, *args, &block|
              RorVsWild.agent.measure_job(job.name, parameters: job.payload_object) { block.call(job) }
            end
          end
        end
        @installed = true
      end
    end
  end
end
