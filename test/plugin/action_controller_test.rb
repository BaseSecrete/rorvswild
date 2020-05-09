require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "action_controller"

class RorVsWild::Plugin::ActionControllerTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_around_action
    agent.start_request
    controller = SampleController.new
    payload = {controller: "SampleController", action: "index", headers: {"action_controller.instance" => controller}}
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))

    assert_equal(1, agent.current_data[:sections].size)
    assert(agent.current_data[:sections][0].total_runtime >= 10)
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", agent.current_data[:name])
  end

  def test_after_exception
    agent.start_request
    controller = SampleController.new
    controller.stubs(request: stub(filtered_parameters: {foo: "bar"}, filtered_env: {"HTTP_CONTENT_TYPE" => "HTML"}))
    assert_raises(ZeroDivisionError) { RorVsWild::Plugin::ActionController.after_exception(ZeroDivisionError.new, controller) }

    data = agent.current_data
    assert_equal("ZeroDivisionError", data[:error][:exception])
    assert_equal({id: "session"}, data[:error][:session])
    assert_equal({foo: "bar"}, data[:error][:parameters])
    assert_equal({"Content-Type" => "HTML"}, data[:error][:environment_variables])
  end

  class SecretController
    def index
    end

    def action_name
      "index"
    end

    def method_for_action(name)
      name
    end
  end

  def test_callback_when_action_is_ignored
    agent.start_request
    controller = SecretController.new
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))
    refute(agent.current_data[:name])
  end

  class SampleController
    def index
      sleep(0.01)
    end

    def method_for_action(name)
      name
    end

    def action_name
      "index"
    end

    def session
      {id: "session"}
    end
  end

  def test_format_header_name
    assert_equal("Content-Type", RorVsWild::Plugin::ActionController.format_header_name("HTTP_CONTENT_TYPE"))
  end
end

