# frozen_string_literal: true

module RorVsWild
  module Local
    class Queue
      def push_job(data)
        push_to(data, "jobs")
        push_error(data[:error]) if data[:error]
      end

      def push_request(data)
        push_to(data, "requests")
        push_error(data[:error]) if data[:error]
      end

      def push_error(data)
        push_to(data, "errors")
      end

      def requests
        load_data("requests")
      end

      def jobs
        load_data("jobs")
      end

      def errors
        load_data("errors")
      end

      private

      def push_to(data, name)
        data[:queued_at] = Time.now
        data[:uuid] = SecureRandom.uuid
        File.open(File.join(directoy, "#{name}.ndjson"), "a") { |file| file.write(JSON.dump(data) + "\n") }
      end

      def load_data(name)
        File.foreach(File.join(directoy, "#{name}.ndjson")).map { |line| JSON.parse(line, symbolize_names: true) }.reverse rescue []
      end

      def directoy
        dir = File.directory?("tmp") ? "tmp" : Dir.tmpdir
        FileUtils.mkpath(File.join(dir, "rorvswild"))[0]
      end
    end
  end
end
