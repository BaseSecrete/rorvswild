require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "action_controller"

class RorVsWild::Plugin::ActionControllerTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    agent.expects(:post_request)
    payload = {controller: "UsersController", action: "show"}
    ActiveSupport::Notifications.instrument("process_action.action_controller", payload) do
      sleep 0.01
    end

    data = agent.send(:data)
    assert_equal(0, data[:sections].size)
    assert_equal("UsersController#show", data[:name])
    assert(data[:runtime] >= 10)
  end

  def test_callback_when_exception_is_raised
    agent.expects(:post_request)
    request = stub(filtered_parameters: {foo: "bar"}, filtered_env: {"HTTP_CONTENT_TYPE" => "HTML"})
    controller = stub(session: {id: "session"}, request: request)
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
    assert_equal({foo: "bar"}, data[:error][:parameters])
    assert_equal({"Content-Type" => "HTML"}, data[:error][:environment_variables])
  end

  class SecretController
    def index
    end
  end

  def test_callback_when_action_is_ignored
    agent.expects(:post_request).never
    payload = {controller: "SecretController", action: "index"}
    ActiveSupport::Notifications.instrument("process_action.action_controller", payload) { }
    assert_equal({}, agent.send(:data))
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
    assert_equal("/plugin/action_controller_test.rb", agent.data[:sections][0].file)
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", agent.data[:sections][0].command)
  end

  def test_format_header_name
    assert_equal("Content-Type", RorVsWild::Plugin::ActionController.format_header_name("HTTP_CONTENT_TYPE"))
  end
end

