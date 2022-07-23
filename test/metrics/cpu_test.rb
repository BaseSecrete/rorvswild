require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Metrics::CpuTest < Minitest::Test
  def test_total
    cpu = RorVsWild::Metrics::Cpu.new
    cpu.update
    assert(cpu.user >= 0)
    assert(cpu.system >= 0)
    assert(cpu.idle >= 0)
    assert(cpu.waiting >= 0)
    assert(cpu.stolen >= 0)
    assert(cpu.load_average > 0)
    assert(cpu.count >= 1)
  end
end
