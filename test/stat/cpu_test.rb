require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Plugin::CpuTest < Minitest::Test
  def test_total
    cpu = RorVsWild::Stat::Cpu.new
    cpu.refresh_info
    assert(cpu.user >= 0)
    assert(cpu.system >= 0)
    assert(cpu.idle >= 0)
    assert(cpu.waiting >= 0)
    assert(cpu.stolen >= 0)
    assert(cpu.load > 0)
  end
end
