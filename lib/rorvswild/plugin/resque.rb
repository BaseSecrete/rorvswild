module RorVsWild
  module Plugin
    module Resque
      def self.setup
        ::Resque::Job.send(:extend, Resque) if defined?(::Resque::Job)
      end

      def around_perform_rorvswild(*args, &block)
        RorVsWild.measure_block(to_s, &block)
      end
    end
  end
end
