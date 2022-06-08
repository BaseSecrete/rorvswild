require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Metrics::MemoryTest < Minitest::Test
  def test_total
    memory = RorVsWild::Metrics::Memory.new
    memory.update
    assert(memory.ram_total > 0)
    assert(memory.ram_total > memory.ram_free)
    assert(memory.ram_total > memory.ram_cached)

    assert(memory.swap_total > 0)
    assert(memory.swap_total > memory.swap_free)
  end
end
