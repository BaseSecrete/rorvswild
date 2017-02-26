require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "net/http"

class RorVsWild::Plugin::NetHttpTest < Minitest::Test
  def test_callback
    client.measure_block("test") { Net::HTTP.get("ruby-lang.org", "/index.html") }
    assert_equal(1, client.send(:queries).size)
    assert_equal(1, client.send(:queries)[0][:times])
    assert_equal("http", client.send(:queries)[0][:kind])
    assert_match("GET http://ruby-lang.org", client.send(:queries)[0][:command])
  end

  def test_callback_with_https
    client.measure_block("test") { Net::HTTP.get(URI("https://www.ruby-lang.org/index.html")) }
    assert_match("GET https://www.ruby-lang.org", client.send(:queries)[0][:command])
    assert_equal("http", client.send(:queries)[0][:kind])
  end

  private

  def client
    @client ||= initialize_client(app_root: "/rails/root")
  end

  def initialize_client(options = {})
    client = RorVsWild::Client.new(options)
    client.stubs(:post_request)
    client.stubs(:post_job)
    client
  end
end
