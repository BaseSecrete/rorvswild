require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "action_controller"

class RorVsWild::Plugin::ActionControllerTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_around_action
    start_request
    controller = SampleController.new
    controller.action_name = "index"
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))

    assert_equal(1, agent.current_execution.sections.size)
    assert(agent.current_execution.sections[0].total_ms >= 10)
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", agent.current_execution.sections[0].command)
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", agent.current_execution.name)
  end

  def test_around_action_when_method_for_action_returns_nil
    start_request
    controller = SampleController.new
    controller.action_name = "index"
    controller.stubs(method_for_action: nil)
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))

    assert_equal(1, agent.current_execution.sections.size)
    assert(agent.current_execution.sections[0].total_ms >= 10)
    assert_equal("", agent.current_execution.sections[0].command)
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", agent.current_execution.name)
  end

  def test_after_exception
    start_request
    RorVsWild.merge_error_context(user_id: 123)
    RorVsWild.merge_error_context(other_id: 456)
    controller = SampleController.new
    controller.action_name = "index"
    controller.stubs(:index).raises(ZeroDivisionError)
    controller.stubs(
      request: stub(
        method: "GET",
        url: "http://localhost:3000/test",
        filtered_parameters: {foo: "bar"},
        filtered_env: {"HTTP_CONTENT_TYPE" => "HTML"},
      )
    )

    assert_raises(StandardError) do
      RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))
    end

    data = agent.current_execution.error.as_json
    assert_equal("ZeroDivisionError", data[:exception])
    assert_equal({foo: "bar"}, data[:parameters])
    assert_equal({"Content-Type" => "HTML"}, data[:request][:headers])
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", data[:request][:name])
    assert_equal("http://localhost:3000/test", data[:request][:url])
    assert_equal("GET", data[:request][:method])
    assert(data[:environment][:os])
    assert(data[:environment][:revision])
    assert_equal({user_id: 123, other_id: 456}, data[:context])
  end

  def test_around_action_for_api_controller
    start_request
    controller = ApiController.new
    controller.action_name = "index"
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))
    assert(agent.current_execution.name)
  end

  def test_callback_when_action_is_ignored
    start_request
    controller = SecretController.new
    controller.action_name = "index"
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))
    refute(agent.current_execution.name)
  end

  class SampleController < ActionController::Base
    def index
      sleep(0.01)
    end
  end

  class SecretController < ActionController::Base
    def index
    end

    def method_for_action(name)
      name
    end
  end

  class ApiController < ActionController::API
    def index
    end
  end
end

