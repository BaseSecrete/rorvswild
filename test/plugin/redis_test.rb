puts path = File.expand_path("#{File.dirname(__FILE__)}/../../lib")
$LOAD_PATH.unshift(path)


require "redis"
require "rorvswild"

require "minitest/autorun"
require 'mocha/mini_test'
require "top_tests"

class RorVsWild::Plugin::RedisTest < Minitest::Test
  def test_callback
    RorVsWild::Plugin::Redis.setup
    client.measure_code("::Redis.new.keys")
    assert_equal(1, client.send(:queries).size)
    assert_equal("redis", client.send(:queries)[0][:type])
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
