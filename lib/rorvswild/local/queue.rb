# frozen_string_literal: true

module RorVsWild
  module Local
    class Queue
      def initialize(config = {})
        @config = config
        dir = File.directory?("tmp") ? "tmp" : Dir.tmpdir
        @directoy = File.join(dir, "rorvswild", @config[:prefix].to_s)
        FileUtils.mkpath(@directoy)
      end

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
        File.open(File.join(@directoy, "#{name}.ndjson"), "a") { |file| file.write(JSON.dump(data) + "\n") }
      end

      def load_data(name)
        path = File.join(@directoy, "#{name}.ndjson")
        read_last_lines(path, 1000).map { |line| JSON.parse(line, symbolize_names: true) }.reverse! rescue []
      end

      def read_last_lines(path, desired_lines, max_read_size = 4096 * desired_lines)
        read_lines, buffer = 0, String.new
        File.open(path, "rb") do |file|
          file.seek(0, IO::SEEK_END)
          pos = file.pos
          while pos > 0 && read_lines <= desired_lines
            read_size = max_read_size < pos ? max_read_size : pos
            file.seek(pos -= read_size, IO::SEEK_SET)
            str = file.read(read_size)
            read_lines += str.count("\n")
            buffer.concat(str)
          end
        end
        buffer.lines[-desired_lines..-1]
      end
    end
  end
end
