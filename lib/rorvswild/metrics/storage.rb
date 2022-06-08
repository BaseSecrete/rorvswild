module RorVsWild
  class Metrics
    class Storage
      attr_reader :used, :free

      def update
        array = `df | grep " /$"`.split
        @used, @free = array[2..3].map(&:to_i)
      end

      def total
        used + free
      end
    end
  end
end
