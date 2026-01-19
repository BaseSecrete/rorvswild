require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Plugin::RackTest < Minitest::Test
  include RorVsWild::AgentHelper

  FAKE_MIDDLEWARE_LINE = __LINE__ + 2
  class FakeMiddleware
    def call(env)
    end
  end

  def test_process_middleware_callback
    agent.measure_block("test") do
      ActiveSupport::Notifications.instrument("process_middleware.action_dispatch", {middleware: "RorVsWild::Plugin::RackTest::FakeMiddleware"}) do
        sleep 0.001
      end
    end

    sections = current_user_sections
    section = sections.find { |s| s.kind == "rack" }

    assert(section)
    assert_equal("rack", section.kind)
    assert_equal("RorVsWild::Plugin::RackTest::FakeMiddleware", section.command)
    assert_equal(1, section.calls)
    assert_equal(FAKE_MIDDLEWARE_LINE, section.line)
    assert(section.file.end_with?("rack_test.rb"))
    assert(section.total_ms >= 1)
  end
end
