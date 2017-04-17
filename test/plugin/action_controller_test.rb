require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "action_controller"

class RorVsWild::Plugin::ActionControllerTest < Minitest::Test
  include RorVsWildAgentHelper

  def test_callback
    agent.expects(:post_request)
    payload = {controller: "UsersController", action: "show"}
    ActiveSupport::Notifications.instrument("process_action.action_controller", payload) do
      sleep 0.01
    end

    data = agent.send(:data)
    assert_equal(0, data[:sections].size)
    assert_equal("UsersController#show", data[:name])
    assert(data[:runtime] > 10)
  end

  def test_callback_when_exception_is_raised
    agent.expects(:post_request)
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

    data = agent.send(:data)
    assert_equal("UsersController#show", data[:name])
    assert_equal("ZeroDivisionError", data[:error][:exception])
    assert_equal({id: "session"}, data[:error][:session])
    assert_equal({header: "env"}, data[:error][:environment_variables])
  end

  class SampleController
    def index
    end
  end

  def test_around_action
    controller = SampleController.new
    controller.stubs(action_name: "index", controller_name: "SampleController", method_for_action: "index")
    agent.measure_block("test") do
      RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))
    end
    assert_equal(1, agent.data[:sections].size)
    assert_equal(__FILE__, agent.data[:sections][0].file)
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", agent.data[:sections][0].command)
  end
end

