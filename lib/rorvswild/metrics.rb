module RorVsWild
  class Metrics
    UPDATE_INTERVAL_MS = 60_000 # One metric every minute

    attr_reader :cpu, :memory, :storage, :updated_at

    def initialize
      @cpu = RorVsWild::Metrics::Cpu.new
      @memory = RorVsWild::Metrics::Memory.new
      @storage = RorVsWild::Metrics::Storage.new
    end

    def update
      if staled?
        cpu.update
        memory.update
        storage.update
        @updated_at = RorVsWild.clock_milliseconds
      end
    end

    def staled?
      !updated_at || RorVsWild.clock_milliseconds - updated_at > UPDATE_INTERVAL_MS
    end

    def to_h
      {
        hostname: Socket.gethostname,
        os: RorVsWild.agent.os_description,
        cpu_user: cpu.user,
        cpu_system: cpu.system,
        cpu_idle: cpu.idle,
        cpu_waiting: cpu.waiting,
        cpu_stolen: cpu.stolen,
        load_average: cpu.load_average,
        ram_total: memory.ram_total,
        ram_free: memory.ram_free,
        ram_used: memory.ram_used,
        ram_cached: memory.ram_cached,
        swap_total: memory.swap_total,
        swap_used: memory.swap_used,
        swap_free: memory.swap_free,
        storage_total: storage.total,
        storage_used: storage.used,
        storage_free: storage.free,
      }
    end
  end
end

require "rorvswild/metrics/cpu"
require "rorvswild/metrics/memory"
require "rorvswild/metrics/storage"
