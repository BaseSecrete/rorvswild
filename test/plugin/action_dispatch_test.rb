require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "action_dispatch"

class RorVsWild::Plugin::ActionDispatchTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    agent # Load agent
    payload = {request: stub(original_fullpath: "/foo/bar")}
    ActiveSupport::Notifications.instrument("request.action_dispatch", payload) { sleep(0.01) }
    assert_equal("/foo/bar", agent.current_data[:path])
    assert_equal(1, agent.current_data[:sections].size)
    assert(agent.current_data[:sections][0].total_runtime >= 10)
  end
end

