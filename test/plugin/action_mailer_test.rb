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

    sections = current_user_sections
    assert_equal(1, sections.size)
    assert_equal("Mailer", sections[0].command)
    assert_equal(line, sections[0].line.to_i)
    assert_equal("mail", sections[0].kind)
    assert(sections[0].self_ms >= 10)
    assert_equal(1, sections[0].calls)
  end
end

