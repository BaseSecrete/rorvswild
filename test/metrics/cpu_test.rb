require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Metrics::CpuTest < Minitest::Test
  def test_total
    cpu = RorVsWild::Metrics::Cpu.new
    sleep(0.01) # Let the CPU runs few cycles
    cpu.update
    assert(cpu.user >= 0)
    assert(cpu.system >= 0)
    assert(cpu.idle >= 0)
    assert(cpu.waiting >= 0)
    assert(cpu.stolen >= 0)
    assert(cpu.load_average > 0)
    assert(cpu.count >= 1)
  end

  def test_parse_stat
    stat = RorVsWild::Metrics::Cpu::Stat.parse("cpu  25473324 131718 6119826 388584745 101095 0 191592 1 2 3")
    assert_equal(25473324, stat.user)
    assert_equal(131718, stat.nice)
    assert_equal(6119826, stat.system)
    assert_equal(388584745, stat.idle)
    assert_equal(101095, stat.iowait)
    assert_equal(0, stat.irq)
    assert_equal(191592, stat.softirq)
    assert_equal(1, stat.steal)
    assert_equal(2, stat.guest)
    assert_equal(3, stat.guest_nice)
    assert_equal(420602306, stat.total)
  end

  def test_read_stat
    assert(RorVsWild::Metrics::Cpu::Stat.read.user > 0)
  end
end
