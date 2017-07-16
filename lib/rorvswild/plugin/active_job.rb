module RorVsWild
  module Plugin
    module ActiveJob
      def self.setup
        return if @installed
        return unless defined?(::ActiveJob::Base)
        ::ActiveJob::Base.around_perform(&method(:around_perform))
        @installed = true
      end

      def self.around_perform(job, block)
        RorVsWild.agent.measure_job(job.class.name, parameters: job.arguments, &block)
      end
    end
  end
end
