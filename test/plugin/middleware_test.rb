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
end

