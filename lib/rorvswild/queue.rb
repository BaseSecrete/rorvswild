module RorVsWild
  class Queue
    SLEEP_TIME = 10
    FLUSH_TRESHOLD = 10

    attr_reader :mutex, :thread, :client
    attr_reader :requests, :jobs

    def initialize(client)
      @jobs = []
      @requests = []
      @client = client
      @mutex = Mutex.new
      @thread = Thread.new { flush_indefinetely }
    end

    def push_job(data)
      push_to(jobs, data)
    end

    def push_request(data)
      push_to(requests, data)
    end

    def push_to(array, data)
      mutex.synchronize do
        array.push(data)
        thread.wakeup if array.size >= FLUSH_TRESHOLD
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

    def pull_requests
      mutex.synchronize do
        if requests.size > 0
          result = requests
          @requests = []
          return result
        end
      end
    end

    def flush_indefinetely
      sleep(SLEEP_TIME) and flush while true
    rescue => ex
      RorVsWild.agent.logger.error(ex.inspect)
      retry
    end

    def flush
      data = pull_jobs and client.post("/jobs", jobs: data)
      data = pull_requests and client.post("/jobs", requests: data)
    end
  end
end
