module RorVsWild
  class Metrics
    class Memory
      attr_reader :ram_total, :ram_cached, :ram_free
      attr_reader :swap_total, :swap_free

      def ram_used
        ram_total - ram_free
      end

      def swap_used
        swap_total - swap_free
      end

      def update
        info = read_meminfo
        @ram_total = convert_to_bytes(info["MemTotal"])
        @ram_free = convert_to_bytes(info["MemFree"])
        @ram_cached = convert_to_bytes(info["Cached"])
        @swap_total = convert_to_bytes(info["SwapTotal"])
        @swap_free = convert_to_bytes(info["SwapFree"])
      end

      private

      def units
        {"kb" => 1000, "mb" => 1000 * 1000, "gb" => 1000 * 1000 * 1000}
      end

      def read_meminfo
        return unless File.readable?("/proc/meminfo")
        File.read("/proc/meminfo").split("\n").reduce({}) do |hash, line|
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
