module RorVsWild
  class Metrics
    attr_reader :cpu, :memory, :storage, :updated_at

    def initialize
      @cpu = RorVsWild::Metrics::Cpu.new
      @memory = RorVsWild::Metrics::Memory.new
      @storage = RorVsWild::Metrics::Storage.new
    end

    def update
      cpu.update
      memory.update
      storage.update
    end

    def update_every_minute
      return unless Host.os.include?("Linux")
      if !@updated_at || @updated_at.min != Time.now.min
        @updated_at = Time.now
        update
      end
    end

    def to_h
      {
        hostname: Host.name,
        os: Host.os,
        cpu_user: cpu.user,
        cpu_system: cpu.system,
        cpu_idle: cpu.idle,
        cpu_waiting: cpu.waiting,
        cpu_stolen: cpu.stolen,
        cpu_count: cpu.count,
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
