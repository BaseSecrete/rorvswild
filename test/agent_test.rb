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
    sections = agent.current_execution.sections
    parent, child = sections[1], sections[0]
    assert_equal("child", child.command)
    assert_equal("parent", parent.command)
    assert(child.self_ms >= 20)
    assert(parent.self_ms >= 10)
    assert(child.self_ms > parent.self_ms)
    assert_equal(child.total_ms + parent.self_ms, parent.total_ms)
  end

  def test_measure_section_with_exception
    assert_raises(ZeroDivisionError) do
      agent.measure_block("root") do
        agent.measure_block("parent") do
          agent.measure_block("child") { 1 / 0 }
        end
      end
    end
    assert_equal(2, current_sections_without_gc.size)
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
    assert_equal(1, (sections = current_sections_without_gc).size)
    assert_equal("child", sections[0].command)
  end

  class Example
    def self.foo
      1
    end

    def bar
      2
    end
  end

  def test_measure_class_method
    line = Example.method(:foo).source_location[1]
    agent.measure_method(Example.method(:foo))
    agent.measure_job("job") { assert_equal(1, Example.foo) }
    section = current_sections_without_gc.first
    assert_equal("code", section.kind)
    assert_equal("/agent_test.rb", section.file)
    assert_equal(line, section.line)
    assert_equal("RorVsWild::AgentTest::Example.foo", section.commands.to_a.join)
  end

  def test_measure_instance_method
    line = Example.instance_method(:bar).source_location[1]
    agent.measure_method(Example.instance_method(:bar))
    agent.measure_job("job") { assert_equal(2, Example.new.bar) }
    section = current_sections_without_gc.first
    assert_equal("code", section.kind)
    assert_equal("/agent_test.rb", section.file)
    assert_equal(line, section.line)
    assert_equal("RorVsWild::AgentTest::Example#bar", section.commands.to_a.join)
  end

  def test_ignored_request?
    agent = initialize_agent(ignore_requests: ["ApplicationController#secret"])
    assert(agent.ignored_request?("ApplicationController#secret"))
    refute(agent.ignored_request?("ApplicationController#index"))
    agent = initialize_agent(ignore_requests: [/SecretController/])
    assert(agent.ignored_request?("SecretController#index"))
    assert(agent.ignored_request?("SecretController#show"))
    refute(agent.ignored_request?("ApplicationController#index"))
  end

  def test_ignored_jobs?
    agent = initialize_agent(ignore_jobs: ["SecretJob"])
    assert(agent.ignored_job?("SecretJob"))
    refute(agent.ignored_job?("ApplicationJob"))
    agent = initialize_agent(ignore_jobs: [/SecretJob/])
    assert(agent.ignored_job?("SecretJob"))
    assert(agent.ignored_job?("AnotherSecretJob"))
    refute(agent.ignored_job?("ApplicationJob"))
  end

  def test_ignored_exception?
    agent = initialize_agent(ignore_exceptions: ["ZeroDivisionError"])
    assert(agent.ignored_exception?(ZeroDivisionError.new))
    refute(agent.ignored_exception?(StandardError.new))
    agent = initialize_agent(ignore_exceptions: [/.*/])
    assert(agent.ignored_exception?(ZeroDivisionError.new))
    assert(agent.ignored_exception?(StandardError.new))
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

  def test_record_error
    agent.queue.expects(:push_error)
    agent.measure_job("test") { agent.record_error(StandardError.new) }
  end

  def test_record_error_when_ignored
    agent.queue.expects(:push_error).never
    agent.config[:ignore_exceptions] = ["StandardError"]
    agent.measure_job("test") { agent.record_error(StandardError.new) }
  end

  def test_record_error_when_already_caught
    agent.queue.expects(:push_error).never
    agent.measure_job("test") do
      agent.current_execution.add_exception(exception = StandardError.new)
      agent.record_error(exception)
    end
  end
end
