module RorVsWild
  module Plugin
    module Resque
      def self.setup
        return if @installed
        ::Resque::Job.send(:extend, Resque) if defined?(::Resque::Job)
        @installed = true
      end

      def around_perform_rorvswild(*args, &block)
        RorVsWild.agent.measure_job(to_s, parameters: args, &block)
      end
    end
  end
end
