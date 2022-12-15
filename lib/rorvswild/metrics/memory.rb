module RorVsWild
  class Metrics
    class Memory
      attr_reader :ram_total, :ram_free, :ram_available, :ram_buffers, :ram_cached
      attr_reader :swap_total, :swap_free
      attr_reader :storage_total, :storage_used

      def ram_used
        ram_total - ram_available
      end

      def swap_used
        swap_total - swap_free
      end

      PROC_MEMINFO = "/proc/meminfo".freeze
      MEM_TOTAL = "MemTotal" # Total usable RAM (i.e., physical RAM minus a few reserved bits and the kernel binary code).
      MEM_FREE = "MemFree" # The sum of LowFree+HighFree.
      MEM_AVAILABLE = "MemAvailable" # An estimate of how much memory is available for starting new applications, without swapping.
      BUFFERS = "Buffers" # Relatively temporary storage for raw disk blocks that shouldn't get tremendously large (20MB or so).
      CACHED = "Cached" # In-memory cache for files read from the disk (the page cache).  Doesn't include SwapCached.
      SWAP_TOTAL = "SwapTotal" # Total amount of swap space available.
      SWAP_FREE = "SwapFree" # Amount of swap space that is currently unused.

      def update
        return unless info = read_meminfo
        @ram_total = convert_to_bytes(info[MEM_TOTAL])
        @ram_free = convert_to_bytes(info[MEM_FREE])
        @ram_available = convert_to_bytes(info[MEM_AVAILABLE])
        @ram_buffers = convert_to_bytes(info[BUFFERS])
        @ram_cached = convert_to_bytes(info[CACHED])
        @swap_total = convert_to_bytes(info[SWAP_TOTAL])
        @swap_free = convert_to_bytes(info[SWAP_FREE])
      end

      private

      def units
        @units ||= {"kb" => 1000, "mb" => 1000 * 1000, "gb" => 1000 * 1000 * 1000}.freeze
      end

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
