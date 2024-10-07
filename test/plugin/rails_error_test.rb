# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::RailsErrorTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_report
    rails = stub(error: ActiveSupport::ErrorReporter.new)
    RorVsWild::Plugin::RailsError.stub_const(:Rails, rails) do
      RorVsWild::Plugin::RailsError.setup
      agent.queue.expects(:push_error)
      rails.error.report(Exception.new("Test"))
    end
  end
end
