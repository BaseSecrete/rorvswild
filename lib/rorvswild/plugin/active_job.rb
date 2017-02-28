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
        RorVsWild.measure_block(job.class.name, &block)
      end
    end
  end
end
