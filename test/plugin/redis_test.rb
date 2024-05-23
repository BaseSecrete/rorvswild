require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "redis"

class RorVsWild::Plugin::RedisTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    agent.measure_code("::Redis.new.get('foo')")
    sections = current_sections_without_gc
    assert_equal(1, sections.size)
    assert_equal("redis",sections[0].kind)
    assert_equal("get",sections[0].command.to_s)
  end

  def test_callback_when_pipelined
    agent.measure_block("pipeline") do
      (redis = ::Redis.new).pipelined do |pipeline|
        pipeline.get("foo")
        pipeline.set("foo", "bar")
      end
    end
    sections = current_sections_without_gc
    assert_equal(1, sections.size)
    assert_equal("redis", sections[0].kind)
    if Redis::VERSION >= "5"
      assert_equal("pipeline", sections[0].command)
    else
      assert_equal("get\nset", sections[0].command)
    end
  end

  def test_callback_when_multi
    agent.measure_block("multi") do
      (redis = ::Redis.new).multi do |transaction|
        transaction.get("foo")
        transaction.set("foo", "bar")
      end
    end
    sections = current_sections_without_gc
    assert_equal(1, sections.size)
    assert_equal("redis", sections[0].kind)
    if Redis::VERSION >= "5"
      assert_equal("multi", sections[0].command)
    else
      assert_equal("multi\nget\nset\nexec", sections[0].command)
    end
  end
end
