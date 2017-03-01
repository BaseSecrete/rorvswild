path = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift(path)

require "rorvswild"
require "minitest/autorun"
require "mocha/mini_test"
require "top_tests"

module RorVsWildClientHelper
  def client
    @client ||= initialize_client(app_root: File.dirname(__FILE__))
  end

  def initialize_client(options = {})
    client ||= RorVsWild::Client.new(options)
    client.stubs(:post_request)
    client.stubs(:post_job)
    client
  end
end
