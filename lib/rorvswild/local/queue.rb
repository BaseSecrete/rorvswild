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
        array = load_data(name)
        array.unshift(data)
        array.pop if array.size > 100
        save_data(array, name)
      end

      def save_data(data, name)
        File.open(File.join(directoy, "#{name}.json"), "w") { |file| JSON.dump(data, file) }
      end

      def load_data(name)
        JSON.load_file(File.join(directoy, "#{name}.json")) rescue []
      end

      def directoy
        dir = File.directory?("tmp") ? "tmp" : Dir.tmpdir
        FileUtils.mkpath(File.join(dir, "rorvswild"))[0]
      end
    end
  end
end
