require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "redis"

class RorVsWild::Plugin::RedisTest < Minitest::Test
  include RorVsWildAgentHelper

  def test_callback
    agent.measure_code("::Redis.new.get('foo')")
    assert_equal(1, agent.send(:sections).size)
    assert_equal("redis", agent.send(:sections)[0].kind)
    assert_equal("get foo", agent.send(:sections)[0].command)
  end

  def test_callback_when_pipelined
    agent.measure_block("pipeline") do
      (redis = ::Redis.new).pipelined do
        redis.get("foo")
        redis.set("foo", "bar")
      end
    end
    assert_equal(1, agent.send(:sections).size)
    assert_equal("redis", agent.send(:sections)[0].kind)
    assert_equal("get foo\nset foo bar", agent.send(:sections)[0].command)
  end

  def test_commands_to_string_hide_auth_password
    assert_equal("auth *****", RorVsWild::Plugin::Redis.commands_to_string([[:auth, "SECRET"]]))
  end
end
