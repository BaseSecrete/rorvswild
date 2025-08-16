# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../helper")

class RorVsWild::Plugin::RailsErrorTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_report
    RorVsWild::Plugin::RailsError.instance_variable_set(:@installed, false)
    rails = stub(error: ActiveSupport::ErrorReporter.new)
    RorVsWild::Plugin::RailsError.stub_const(:Rails, rails) do
      RorVsWild::Plugin::RailsError.setup
      agent.queue.expects(:push_error)
      rails.error.report(Exception.new("Test"))
    end
  end

  def test_report_with_given_context
    rails = stub(error: ActiveSupport::ErrorReporter.new)
    RorVsWild::Plugin::RailsError.instance_variable_set(:@installed, false)
    RorVsWild::Plugin::RailsError.stub_const(:Rails, rails) do
      RorVsWild::Plugin::RailsError.setup
      queue = agent.queue
      def queue.push_error(error) = @error = error
      def queue.error = @error
      rails.error.report(Exception.new("Test"), context: {foo: "bar"})
      assert_equal({foo: "bar"}, queue.error[:context])
    end
  end
end
