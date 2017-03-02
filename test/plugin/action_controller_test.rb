require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_support"

class RorVsWild::Plugin::ActionControllerTest < Minitest::Test
  include RorVsWildClientHelper

  def test_callback
    client.measure_block("test") do
      payload = {controller: "UsersController", action: "show"}
      ActiveSupport::Notifications.instrument("process_action.action_controller", payload) do
        sleep 0.1
      end
    end

    sections = client.send(:sections)
    assert_equal(1, sections.size)
    assert_equal("UsersController#show", sections[0].command)
  end
end

