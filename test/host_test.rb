require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::HostTest < Minitest::Test
  def test_to_h
    hash = RorVsWild::Host.to_h
    assert(hash[:os])
    assert(hash[:user])
    assert(hash[:host])
    assert(hash[:ruby])
    assert(hash[:pid])
    assert(hash[:cwd])
    assert(hash[:revision])
    assert(hash[:revision_description])
  end
end
