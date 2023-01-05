require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::Metrics::CpuTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_to_h
    agent
    metrics = RorVsWild::Metrics.new
    sleep(0.01) # Let the CPU runs few cycles
    assert(metrics.update)
    assert_kind_of(Hash, hash = metrics.to_h)
    assert(hash[:hostname])
    assert(hash[:os])
    assert_operator(hash[:cpu_user], :>=, 0)
    assert_operator(hash[:cpu_system], :>=, 0)
    assert_operator(hash[:cpu_idle], :>=, 0)
    assert_operator(hash[:cpu_waiting], :>=, 0)
    assert_operator(hash[:cpu_stolen], :>=, 0)
    assert_operator(hash[:cpu_count], :>=, 0)
    assert_operator(hash[:load_average], :>=, 0)
    assert_operator(hash[:ram_total], :>=, 0)
    assert_operator(hash[:ram_free], :>=, 0)
    assert_operator(hash[:ram_used], :>=, 0)
    assert_operator(hash[:ram_cached], :>=, 0)
    assert_operator(hash[:swap_total], :>=, 0)
    assert_operator(hash[:swap_free], :>=, 0)
    assert_operator(hash[:swap_used], :>=, 0)
    assert_operator(hash[:storage_total], :>=, 0)
    assert_operator(hash[:storage_free], :>=, 0)
    assert_operator(hash[:storage_used], :>=, 0)
  end
end
