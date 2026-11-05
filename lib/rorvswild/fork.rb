# frozen_string_literal: true

# Fork safety: https://github.com/Shopify/pitchfork/blob/master/docs/FORK_SAFETY.md
module RorVsWild
  class Client
    def after_fork
      @mutex = Mutex.new
      @connections = []
      @connection_count = 0
      @threads = Set.new
    end
  end

  class Queue
    def after_fork
      running = @thread
      @mutex = Mutex.new
      @thread = nil
      start_thread if running
    end
  end

  def self.after_fork
    return unless agent
    agent.client.after_fork if agent.client
    agent.queue.after_fork if agent.queue
  end

  if Process.respond_to?(:_fork)
    module ForkTracker
      def _fork
        RorVsWild.after_fork if (pid = super) == 0
        pid
      end
    end
    Process.singleton_class.prepend(ForkTracker)
  end
end
