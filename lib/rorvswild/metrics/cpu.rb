module RorVsWild
  class Metrics
    class Cpu
      attr_reader :user, :system, :idle, :waiting, :stolen
      attr_reader :load_average, :count

      def update
        if vmstat = execute(:vmstat)
          vmstat = vmstat.split("\n").last.split
          @user = vmstat[12].to_i
          @system = vmstat[13].to_i
          @idle = vmstat[14].to_i
          @waiting = vmstat[15].to_i
          @stolen = vmstat[16].to_i
        end
        if uptime = execute(:uptime)
          @load_average = uptime.split[-3].to_f
        end
        if nproc = execute(:nproc)
          @count = nproc.to_i
        end
      end

      def execute(command)
        `#{command}`
      rescue => ex
        nil
      end
    end
  end
end
