require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWildTest < Minitest::Test
  include RorVsWild::AgentHelper
  include TopTests

  def test_measure_code
    agent.expects(:post_job)
    assert_equal(2, agent.measure_code("sleep(0.001); 1 + 1"))
    assert_equal("sleep(0.001); 1 + 1", agent.send(:data)[:name])
    assert(agent.send(:data)[:runtime] >= 1)
  end

  def test_measure_code_when_raising
    agent.expects(:post_job)
    assert_raises(RuntimeError) { agent.measure_code("raise 'error'") }
    assert_equal(("raise 'error'"), agent.send(:data)[:name])
    assert(agent.send(:data)[:runtime])
    assert(agent.send(:data)[:error])
  end

  def test_mesure_block_when_exception_is_ignored
    agent = initialize_agent(ignored_exceptions: %w[ZeroDivisionError])
    agent.expects(:post_job)
    assert_raises(ZeroDivisionError) { RorVsWild.measure_code("1/0") }
    refute(agent.send(:data)[:error])
  end

  def test_measure_code_when_no_agent
    RorVsWild.instance_variable_set(:@agent, nil)
    RorVsWild::Agent.any_instance.expects(:post_job).never
    assert_equal(2, RorVsWild.measure_code("1+1"))
  end

  def test_measure_block_when_no_agent
    RorVsWild.instance_variable_set(:@agent, nil)
    RorVsWild::Agent.any_instance.expects(:post_job).never
    assert_equal(2, RorVsWild.measure_block("1+1") { 1+1 })
  end

  def test_measure_block_recursive
    agent.expects(:post_job)
    result = RorVsWild.measure_block("1") do
      RorVsWild.measure_block("2") { 1 } + 1
    end
    assert_equal(2, result)
  end

  def test_catch_error
    agent.expects(:post_error)
    exception = RorVsWild.catch_error { 1 / 0 }
    assert_equal(ZeroDivisionError, exception.class)
  end

  def test_catch_error_with_extra_details
    agent.expects(:post_error)
    exception = RorVsWild.catch_error(foo: "bar") { 1 / 0 }
    assert_equal(ZeroDivisionError, exception.class)
  end

  def test_catch_error_when_no_errors
    agent.expects(:post_error).never
    assert_equal(2, RorVsWild.catch_error { 1 + 1 })
  end
end
