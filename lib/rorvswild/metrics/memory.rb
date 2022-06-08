module RorVsWild
  class Metrics
    class Memory
      attr_reader :ram_total, :ram_cached, :ram_free
      attr_reader :swap_total, :swap_free
      attr_reader :storage_total, :storage_used

      def ram_used
        ram_total - ram_free
      end

      def swap_used
        swap_total - swap_free
      end

      def update
        info = read_meminfo
        @ram_total = convert_to_bytes(info["MemTotal".freeze])
        @ram_free = convert_to_bytes(info["MemFree".freeze])
        @ram_cached = convert_to_bytes(info["Cached".freeze])
        @swap_total = convert_to_bytes(info["SwapTotal".freeze])
        @swap_free = convert_to_bytes(info["SwapFree".freeze])
      end

      private

      def units
        @unites ||= {"kb" => 1000, "mb" => 1000 * 1000, "gb" => 1000 * 1000 * 1000}.freeze
      end

      PROC_MEMINFO = "/proc/meminfo".freeze

      def read_meminfo
        return unless File.readable?(PROC_MEMINFO)
        File.read(PROC_MEMINFO).split("\n").reduce({}) do |hash, line|
          name, value = line.split(":")
          hash[name] = value.strip
          hash
        end
      end

      def convert_to_bytes(string)
        value, unit = string.split
        value.to_i * units[unit.downcase]
      end
    end
  end
end
