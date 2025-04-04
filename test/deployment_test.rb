require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::DeploymentTest < Minitest::Test
  def setup
    for name in [:@description, :@revision, :@author, :@email, :@to_h]
      if RorVsWild::Deployment.instance_variable_defined?(name)
        RorVsWild::Deployment.remove_instance_variable(name)
      end
    end
  end

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

  def test_read_from_kamal
    refute(RorVsWild::Deployment.send(:read_from_kamal))
    stub_env("KAMAL_VERSION" => "123") do
      assert(RorVsWild::Deployment.send(:read_from_kamal))
      assert_equal("123", RorVsWild::Deployment.to_h[:revision])
    end
    refute(RorVsWild::Deployment.send(:read_from_kamal))
  end

  private

  def stub_env(new_hash, &block)
    old_hash = ENV.filter { |name, value| new_hash.keys.include?(name) }
    new_hash.each { |name, value| ENV[name] = value }
    block.call
  ensure
    new_hash.each { |name, value| ENV[name] = old_hash[name] } if old_hash
  end
end
