require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveMailerTest < Minitest::Test
  include RorVsWildAgentHelper

  def test_callback
    line = nil
    agent = initialize_agent(app_root: File.dirname(__FILE__))
    agent.measure_block("test") do
      ActiveSupport::Notifications.instrument("deliver.action_mailer", {mailer: "Mailer"}) do line = __LINE__
        sleep 0.01
      end
    end

    section = agent.data[:sections][0]

    assert_equal(1, agent.data[:sections].size)
    assert_equal("Mailer", section.command)
    assert_equal(line, section.line.to_i)
    assert_equal("mail", section.kind)
    assert(section.self_runtime >= 10)
    assert_equal(1, section.calls)
  end
end

