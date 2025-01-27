require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Plugin::MiddlewareTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    agent # Load agent
    request = {"ORIGINAL_FULLPATH" => "/foo/bar"}
    app = mock(call: nil)
    middleware = RorVsWild::Plugin::Middleware.new(app, nil)
    middleware.stubs(rails_engine_location: ["/rails/lib/engine.rb", 12])
    middleware.call(request)
    assert_equal("/foo/bar", agent.current_data[:path])
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("Rails::Engine#call", agent.current_data[:sections][0].command)
  end

  def test_subrequest_with_async_query
    agent # Load agent
    agent.unstub(:queue_request)
    router = Router.new
    middleware = RorVsWild::Plugin::Middleware.new(router, nil)
    middleware.stubs(rails_engine_location: ["/rails/lib/engine.rb", 12])
    request = {"ORIGINAL_FULLPATH" => "/parent", "rorvswild_middleware" => middleware}

    middleware.call(request)

    assert_equal(
      [
        "Rails::Engine#call",
        "RorVsWild::Plugin::MiddlewareTest::ChildController#index",
        "RorVsWild::Plugin::MiddlewareTest::ParentController#index",
        "SELECT 1"
      ],
      RorVsWild.agent.queue.requests[0][:sections].map { |s| s.commands.join }.sort
    )
  end

  class Router
    def call(env)
      controller = case env["ORIGINAL_FULLPATH"]
      when "/parent" then ParentController.new
      when "/child" then ChildController.new
      else raise "Unknow route"
      end
      controller.rorvswild_middleware = env["rorvswild_middleware"]
      RorVsWild::Plugin::ActionController.around_action(controller, controller.method(:index))
    end
  end

  class BaseController
    attr_accessor :rorvswild_middleware

    def action_name
      :index
    end

    def method_for_action(name)
      :index
    end
  end

  class ParentController < BaseController
    def index
      rorvswild_middleware.call({"ORIGINAL_FULLPATH" => "/child"})
      simulate_async_query
    end

    def simulate_async_query
      section = RorVsWild::Section.new
      section.total_ms = 0
      section.async_ms = 1
      section.gc_time_ms = 0
      section.commands << "SELECT 1"
      section.kind = "sql"
      RorVsWild.agent.add_section(section)
    end
  end

  class ChildController < BaseController
    def index
    end
  end
end

