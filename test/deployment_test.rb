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

  def test_load_config
    RorVsWild::Deployment.load_config(deployment: {revision: "deployment_revision", description: "deployment_description"})
    assert_equal("deployment_revision", RorVsWild::Deployment.revision)
    assert_equal("deployment_description", RorVsWild::Deployment.description)
  end
end
