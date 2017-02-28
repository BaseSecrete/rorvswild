module RorVsWild
  module Plugin
    module DelayedJob
      def self.setup
        return if @installed
        return unless defined?(Delayed::Worker)
        Delayed::Worker.lifecycle.around(:invoke_job, &method(:around_perform))
        @installed = true
      end

      def self.around_perform(job, &block)
        RorVsWild.measure_block(job.name) { block.call(job) }
      end
    end
  end
end
