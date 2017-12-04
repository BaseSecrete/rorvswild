module RorVsWild
  module Local
    class Queue
      attr_reader :requests
      def initialize
        @requests = []
      end

      def push_job(data)
      end

      def push_request(data)
        requests.unshift(data)
        requests.pop if requests.size > 100
      end
    end
  end
end
