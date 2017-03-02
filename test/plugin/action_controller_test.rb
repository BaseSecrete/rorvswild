require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "action_controller"

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

  def test_callback_when_exception_is_raised
    client.expects(:post_request)
    controller = stub(session: {id: "session"}, request: stub(filtered_env: {header: "env"}))
    payload = {controller: "UsersController", action: "show"}
    assert_raises(ZeroDivisionError) do
      ActiveSupport::Notifications.instrument("process_action.action_controller", payload) do
        begin
          1 / 0
        rescue => ex
          RorVsWild::Plugin::ActionController.after_exception(ex, controller)
        end
      end
    end

    data = client.send(:data)
    assert_equal("UsersController#show", data[:name])
    assert_equal("ZeroDivisionError", data[:error][:exception])
    assert_equal({id: "session"}, data[:error][:session])
    assert_equal({header: "env"}, data[:error][:environment_variables])
  end
end

