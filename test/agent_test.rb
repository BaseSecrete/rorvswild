require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::AgentTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_measure_section
    result = agent.measure_block("root") do
      agent.measure_block("parent") do
        sleep 0.01
        agent.measure_block("child") do
          sleep 0.02
          42
        end
      end
    end
    assert_equal(42, result)
    sections = agent.current_data[:sections]
    parent, child = sections[1], sections[0]
    assert_equal("child", child.command)
    assert_equal("parent", parent.command)
    assert(child.self_runtime >= 20)
    assert(parent.self_runtime >= 10)
    assert(child.self_runtime > parent.self_runtime)
    assert_equal(child.total_runtime + parent.self_runtime, parent.total_runtime)
  end

  def test_measure_section_with_exception
    assert_raises(ZeroDivisionError) do
      agent.measure_block("root") do
        agent.measure_block("parent") do
          agent.measure_block("child") { 1 / 0 }
        end
      end
    end
    assert_equal(2, agent.current_data[:sections].size)
  end

  def test_measure_job_when_ignored
    result = agent.measure_job("SecretJob") { "result" }
    assert_equal("result", result)
    refute(agent.current_data)
  end

  def test_measure_job_when_recursive
    agent.measure_job("parent") do
      agent.measure_job("child") { }
    end
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("child", agent.current_data[:sections][0].command)
  end

  def test_hostname
    old_dyno = ENV["DYNO"]
    old_gae = ENV["GAE_INSTANCE"]
    assert_equal(Socket.gethostname, RorVsWild::Host.name)

    ENV["DYNO"] = "web.1"
    RorVsWild::Host.instance_variable_set(:@name, nil)
    assert_equal("web.1", RorVsWild::Host.name, "Heroku dyno")

    ENV["DYNO"] = "release.123"
    RorVsWild::Host.instance_variable_set(:@name, nil)
    assert_equal("release.*", RorVsWild::Host.name, "Group all release dynos")

    ENV["DYNO"] = "run.123"
    RorVsWild::Host.instance_variable_set(:@name, nil)
    assert_equal("run.*", RorVsWild::Host.name, "Group all run dynos")

    ENV["GAE_INSTANCE"] = "gae"
    RorVsWild::Host.instance_variable_set(:@name, nil)
    assert_equal("gae", RorVsWild::Host.name)
  ensure
    ENV["DYNO"] = old_dyno
    ENV["GAE_INSTANCE"] = old_gae
  end
end
