require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "action_controller"

class RorVsWild::Plugin::ActionControllerTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    agent.start_request
    controller = SampleController.new
    payload = {controller: "SampleController", action: "index", headers: {"action_controller.instance" => controller}}
    ActiveSupport::Notifications.instrument("process_action.action_controller", payload) { sleep(0.01) }

    assert_equal(1, agent.data[:sections].size)
    assert(agent.data[:sections][0].total_runtime >= 10)
    assert_equal("SampleController#index", agent.data[:name])
  end

  def test_callback_when_exception_is_raised
    agent.start_request
    controller = SampleController.new
    request = stub(filtered_parameters: {foo: "bar"}, filtered_env: {"HTTP_CONTENT_TYPE" => "HTML"})
    controller.stubs(session: {id: "session"}, request: request)
    payload = {controller: "SampleController", action: "index", headers: {"action_controller.instance" => controller}}
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
    assert_equal("SampleController#index", data[:name])
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
    agent.start_request
    controller = SampleController.new
    payload = {controller: "SecretController", action: "index", headers: {"action_controller.instance" => controller}}
    ActiveSupport::Notifications.instrument("process_action.action_controller", payload) { }
    refute(agent.data[:name])
  end

  class SampleController
    def index
    end

    def method_for_action(name)
      name
    end
  end

  def test_format_header_name
    assert_equal("Content-Type", RorVsWild::Plugin::ActionController.format_header_name("HTTP_CONTENT_TYPE"))
  end
end

