require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveMailerTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    line = nil
    agent.measure_block("test") do
      ActiveSupport::Notifications.instrument("deliver.action_mailer", {mailer: "Mailer"}) do line = __LINE__
        sleep 0.01
      end
    end

    section = agent.current_data[:sections][0]

    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("Mailer", section.command)
    assert_equal(line, section.line.to_i)
    assert_equal("mail", section.kind)
    assert(section.self_runtime >= 10)
    assert_equal(1, section.calls)
  end
end

