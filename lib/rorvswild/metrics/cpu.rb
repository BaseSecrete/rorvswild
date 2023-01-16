# frozen_string_literal: true

module RorVsWild
  class Metrics
    class Cpu
      attr_reader :user, :system, :idle, :waiting, :stolen
      attr_reader :load_average, :count

      def initialize
        @old_stat = Stat.read
      end

      def update
        if @old_stat && (new_stat = Stat.read)
          if (total = new_stat.total - @old_stat.total) > 0
            @user = (new_stat.user - @old_stat.user) * 100 / total
            @system = (new_stat.system - @old_stat.system) * 100 / total
            @idle = (new_stat.idle - @old_stat.idle) * 100 / total
            @waiting = (new_stat.iowait - @old_stat.iowait) * 100 / total
            @stolen = (new_stat.steal - @old_stat.steal) * 100 / total
            @old_stat = new_stat
          end
        end
        @load_average = File.read("/proc/loadavg").to_f if File.readable?("/proc/loadavg")
        @count = `nproc`.to_i rescue nil
      end

      class Stat
        attr_reader :user, :nice, :system, :idle, :iowait, :irq, :softirq, :steal, :guest, :guest_nice, :total

        def initialize(user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice)
          @user = user
          @nice = nice
          @system = system
          @idle = idle
          @iowait = iowait
          @irq = irq
          @softirq = softirq
          @steal = steal
          @guest = guest
          @guest_nice = guest_nice
          @total = user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice
        end

        def self.parse(string)
          for row in string.lines
            return new(*row.split[1..-1].map(&:to_i)) if row.start_with?("cpu ")
          end
          nil
        end

        def self.read
          parse(File.read("/proc/stat")) if File.readable?("/proc/stat")
        end
      end
    end
  end
end
