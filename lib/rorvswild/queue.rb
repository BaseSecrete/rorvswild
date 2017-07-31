module RorVsWild
  class Queue
    SLEEP_TIME = 10
    FLUSH_TRESHOLD = 10

    attr_reader :mutex, :thread, :client
    attr_reader :requests, :jobs

    def initialize(client)
      @jobs = []
      @client = client
      @mutex = Mutex.new
      @thread = Thread.new { flush_indefinetly }
    end

    def push_job(data)
      mutex.synchronize do
        jobs.push(data)
        thread.wakeup if jobs.size >= FLUSH_TRESHOLD
      end
    end

    def pull_jobs
      mutex.synchronize do
        if jobs.size > 0
          result = jobs
          @jobs = []
          return result
        end
      end
    end

    def flush_indefinetly
      sleep(SLEEP_TIME) and flush while true
    end

    def flush
      data = pull_jobs and client.post("/jobs", jobs: data)
    end
  end
end
