require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "redis"

class RorVsWild::Plugin::RedisTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    agent.measure_code("::Redis.new.get('foo')")
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("redis", agent.current_data[:sections][0].kind)
    assert_equal("get", agent.current_data[:sections][0].command.to_s)
  end

  def test_callback_when_pipelined
    agent.measure_block("pipeline") do
      (redis = ::Redis.new).pipelined do |pipeline|
        pipeline.get("foo")
        pipeline.set("foo", "bar")
      end
    end
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("redis", agent.current_data[:sections][0].kind)
    if Redis::VERSION >= "5"
      assert_equal("pipeline", agent.current_data[:sections][0].command)
    else
      assert_equal("get\nset", agent.current_data[:sections][0].command)
    end
  end

  def test_callback_when_multi
    agent.measure_block("multi") do
      (redis = ::Redis.new).multi do |transaction|
        transaction.get("foo")
        transaction.set("foo", "bar")
      end
    end
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("redis", agent.current_data[:sections][0].kind)
    if Redis::VERSION >= "5"
      assert_equal("multi", agent.current_data[:sections][0].command)
    else
      assert_equal("multi\nget\nset\nexec", agent.current_data[:sections][0].command)
    end
  end
end
