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
        data[:queued_at] = Time.now.iso8601(3)
        data[:uuid] = SecureRandom.uuid
        File.open(File.join(@directoy, "#{name}.ndjson"), "a") { |file| file.write(JSON.dump(data) + "\n") }
      end

      def load_data(name)
        return [] unless File.readable?(path = File.join(@directoy, "#{name}.ndjson"))
        return [] unless lines = read_last_lines(path, 100)
        lines.reverse.map { |line| JSON.parse(line, symbolize_names: true) }
      end

      def read_last_lines(path, desired_lines, max_read_size = 4096 * desired_lines)
        read_lines, buffer = 0, []
        File.open(path, "rb") do |file|
          file.seek(0, IO::SEEK_END)
          pos = file.pos
          while pos > 0 && read_lines <= desired_lines
            read_size = max_read_size < pos ? max_read_size : pos
            file.seek(pos -= read_size, IO::SEEK_SET)
            buffer << file.read(read_size)
            read_lines += buffer.last.count("\n")
          end
        end
        lines = buffer.reverse.join.lines
        offset = [lines.size - 1, desired_lines].min
        lines[-offset..-1]
      end
    end
  end
end
