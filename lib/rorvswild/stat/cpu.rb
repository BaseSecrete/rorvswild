module RorVsWild
  module Stat
    class Cpu
      attr_reader :user, :system, :idle, :waiting, :stolen, :load

      def refresh_info
        if !@info_cached_at || RorVsWild.clock_milliseconds - @info_cached_at > 60_000
          vmstat = execute_vmstat
          @user = vmstat[12].to_i
          @system = vmstat[13].to_i
          @idle = vmstat[14].to_i
          @waiting = vmstat[15].to_i
          @stolen = vmstat[16].to_i
          @load = read_loadavg[0].to_f
        end
      end

      def read_loadavg
        return unless File.readable?("/proc/loadavg")
        File.read("/proc/loadavg").split
      end

      def execute_vmstat
        `vmstat`.split("\n").last.split
      rescue Exception => ex
        []
      end
    end
  end
end
