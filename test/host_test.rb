require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::HostTest < Minitest::Test
  def test_to_h
    RorVsWild::Host.instance_variable_set(:@to_h, nil)
    hash = RorVsWild::Host.to_h
    assert(hash[:os])
    assert(hash[:user])
    assert(hash[:host])
    assert(hash[:ruby])
    assert(hash[:pid])
    assert(hash[:cwd])
    assert(hash[:revision])
  end

  def test_initialize_config
    refute_equal("test_initialize_config", RorVsWild::Host.name)
    RorVsWild::Host.load_config(server: {name: "test_initialize_config"})
    assert_equal("test_initialize_config", RorVsWild::Host.name)
  end
end
