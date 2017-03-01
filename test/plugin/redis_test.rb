require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "redis"

class RorVsWild::Plugin::RedisTest < Minitest::Test
  def test_callback
    client.measure_code("::Redis.new.get('foo')")
    assert_equal(1, client.send(:sections).size)
    assert_equal("redis", client.send(:sections)[0].kind)
    assert_equal("get foo", client.send(:sections)[0].command)
  end

  def test_callback_when_pipelined
    client.measure_block("pipeline") do
      (redis = ::Redis.new).pipelined do
        redis.get("foo")
        redis.set("foo", "bar")
      end
    end
    assert_equal(1, client.send(:sections).size)
    assert_equal("redis", client.send(:sections)[0].kind)
    assert_equal("get foo\nset foo bar", client.send(:sections)[0].command)
  end

  def test_commands_to_string_hide_auth_password
    assert_equal("auth *****", RorVsWild::Plugin::Redis.commands_to_string([[:auth, "SECRET"]]))
  end

  private

  def client
    @client ||= initialize_client(app_root: "/rails/root")
  end

  def initialize_client(options = {})
    client ||= RorVsWild::Client.new(options)
    client.stubs(:post_request)
    client.stubs(:post_job)
    client
  end
end
