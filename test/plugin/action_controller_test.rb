require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "action_controller"

class RorVsWild::Plugin::ActionControllerTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_around_action
    agent.start_request
    controller = SampleController.new
    controller.action_name = "index"
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))

    assert_equal(1, agent.current_data[:sections].size)
    assert(agent.current_data[:sections][0].total_runtime >= 10)
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", agent.current_data[:name])
  end

  def test_after_exception
    agent.start_request
    RorVsWild.merge_error_context(user_id: 123)
    RorVsWild.merge_error_context(other_id: 456)
    controller = SampleController.new
    controller.action_name = "index"
    controller.stubs(request: stub(filtered_parameters: {foo: "bar"}, filtered_env: {"HTTP_CONTENT_TYPE" => "HTML"}, method: "GET", url: "http://localhost:3000/test"))
    assert_raises(ZeroDivisionError) { RorVsWild::Plugin::ActionController.after_exception(ZeroDivisionError.new, controller) }

    data = agent.current_data
    assert_equal("ZeroDivisionError", data[:error][:exception])
    assert_equal({id: "session"}, data[:error][:session])
    assert_equal({foo: "bar"}, data[:error][:parameters])
    assert_equal({"Content-Type" => "HTML"}, data[:error][:request][:headers])
    assert_equal("RorVsWild::Plugin::ActionControllerTest::SampleController#index", data[:error][:request][:name])
    assert_equal("http://localhost:3000/test", data[:error][:request][:url])
    assert_equal("GET", data[:error][:request][:method])
    assert(data[:error][:environment][:os])
    assert_equal({user_id: 123, other_id: 456}, data[:error][:extra_details])
  end

  def test_around_action_for_api_controller
    agent.start_request
    controller = ApiController.new
    controller.action_name = "index"
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))
    assert(agent.current_data[:name])
  end

  def test_callback_when_action_is_ignored
    agent.start_request
    controller = SecretController.new
    controller.action_name = "index"
    RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))
    refute(agent.current_data[:name])
  end

  def test_format_header_name
    assert_equal("Content-Type", RorVsWild::Plugin::ActionController.format_header_name("HTTP_CONTENT_TYPE"))
  end

  class SampleController < ActionController::Base
    def index
      sleep(0.01)
    end

    def session
      {id: "session"}
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

