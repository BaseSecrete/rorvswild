require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "redis"

class RorVsWild::Plugin::RedisTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    url = "redis://localhost:6379/1"
    agent.measure_code("::Redis.new(url: '#{url}').get('foo')")
    assert_equal(1, agent.data[:sections].size)
    assert_equal("redis", agent.data[:sections][0].kind)
    assert_equal("select 1\nget foo", agent.data[:sections][0].command)
  end

  def test_callback_when_pipelined
    agent.measure_block("pipeline") do
      (redis = ::Redis.new).pipelined do
        redis.get("foo")
        redis.set("foo", "bar")
      end
    end
    assert_equal(1, agent.data[:sections].size)
    assert_equal("redis", agent.data[:sections][0].kind)
    assert_equal("get foo\nset foo bar", agent.data[:sections][0].command)
  end

  def test_commands_to_string_hide_auth_password
    assert_equal("auth *****", RorVsWild::Plugin::Redis.commands_to_string([[:auth, "SECRET"]]))
  end

  def test_appendable_commands?
    assert(RorVsWild::Plugin::Redis.appendable_commands?([[:select, 1]]))
    assert(RorVsWild::Plugin::Redis.appendable_commands?([[:auth, "SECRET"]]))
    refute(RorVsWild::Plugin::Redis.appendable_commands?([[:get, "KEY"]]))
  end
end
