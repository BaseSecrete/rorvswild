module RorVsWild
  class Queue
    SLEEP_TIME = 30
    FLUSH_TRESHOLD = 10

    attr_reader :mutex, :thread, :client
    attr_reader :requests, :jobs

    def initialize(client)
      @jobs = []
      @requests = []
      @client = client
      @mutex = Mutex.new
      @metrics = RorVsWild::Metrics.new
      Kernel.at_exit { flush }
    end

    def push_job(data)
      push_to(jobs, data)
    end

    def push_request(data)
      push_to(requests, data)
    end

    def push_to(array, data)
      mutex.synchronize do
        wakeup_thread if array.push(data).size >= FLUSH_TRESHOLD || !thread
      end
    end

    def pull_jobs
      result = nil
      mutex.synchronize do
        if jobs.size > 0
          result = jobs
          @jobs = []
        end
      end
      result
    end

    def pull_requests
      result = nil
      mutex.synchronize do
        if requests.size > 0
          result = requests
          @requests = []
        end
      end
      result
    end

    def pull_server_metrics
      @metrics.update && @metrics.to_h
    end

    def flush_indefinetely
      sleep(SLEEP_TIME) and flush while true
    rescue Exception => ex
      RorVsWild.logger.error(ex)
      raise
    end

    def flush
      data = pull_jobs and client.post("/jobs", jobs: data)
      data = pull_requests and client.post("/requests", requests: data)
      data = pull_server_metrics and client.post("/metrics", metrics: data)
    end

    def start_thread
      RorVsWild.logger.debug("RorVsWild::Queue#start_thread".freeze)
      @thread = Thread.new { flush_indefinetely }
    end

    def wakeup_thread
      (thread && thread.alive?) ? thread.wakeup : start_thread
    end
  end
end
