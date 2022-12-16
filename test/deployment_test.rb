require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::DeploymentTest < Minitest::Test
  def test_to_h
    RorVsWild::Deployment.read
    hash = RorVsWild::Deployment.to_h
    assert(hash[:revision])
    assert(hash[:description])
    assert(hash[:author])
    assert(hash[:email])
  end
end
