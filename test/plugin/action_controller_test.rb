require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_support"

class RorVsWild::Plugin::ActionControllerTest < Minitest::Test
  include RorVsWildClientHelper

  def test_callback
    client.expects(:post_request)
    payload = {controller: "UsersController", action: "show"}
    ActiveSupport::Notifications.instrument("process_action.action_controller", payload) do
      sleep 0.01
    end

    data = client.send(:data)
    assert_equal(0, data[:sections].size)
    assert_equal("UsersController#show", data[:name])
    assert(data[:runtime] > 10)
  end
end

