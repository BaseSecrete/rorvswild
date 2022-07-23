module RorVsWild
  class Metrics
    class Storage
      attr_reader :used, :free

      def update
        array = `df -k | grep " /$"`.split
        @used = array[2].to_i * 1000
        @free = array[3].to_i * 1000
      end

      def total
        used + free
      end
    end
  end
end
