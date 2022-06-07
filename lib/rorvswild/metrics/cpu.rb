module RorVsWild
  class Metrics
    class Cpu
      attr_reader :user, :system, :idle, :waiting, :stolen
      attr_reader :load_average

      def update
        vmstat = execute_vmstat
        @user = vmstat[12].to_i
        @system = vmstat[13].to_i
        @idle = vmstat[14].to_i
        @waiting = vmstat[15].to_i
        @stolen = vmstat[16].to_i
        @load_average = read_loadavg[0].to_f
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
