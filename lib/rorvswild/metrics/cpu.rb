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

      PROC_LOADAVG = "/proc/loadavg".freeze

      def read_loadavg
        return unless File.readable?(PROC_LOADAVG)
        File.read(PROC_LOADAVG).split
      end

      def execute_vmstat
        `vmstat`.split("\n").last.split
      rescue Exception => ex
        []
      end
    end
  end
end
