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
        cpu: {
          user: cpu.user,
          system: cpu.system,
          idle: cpu.idle,
          waiting: cpu.waiting,
          stolen: cpu.stolen,
          load_average: cpu.load_average,
        },
        memory: {
          ram_total: memory.ram_total,
          ram_used: memory.ram_used,
          ram_free: memory.ram_free,
          ram_cached: memory.ram_cached,
          swap_total: memory.swap_total,
          swap_used: memory.swap_used,
          swap_free: memory.swap_free,
        },
        storage: {
          total: storage.total,
          used: storage.used,
          free: storage.free,
        },
      }
    end
  end
end

require "rorvswild/metrics/cpu"
require "rorvswild/metrics/memory"
require "rorvswild/metrics/storage"
