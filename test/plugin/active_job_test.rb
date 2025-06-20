require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveJobTest < Minitest::Test
  include RorVsWild::AgentHelper

  class RetriedError < StandardError; end
  class DiscardedError < StandardError; end
  class RescuedError < StandardError; end

  class SampleJob < ::ActiveJob::Base
    queue_as :default

    retry_on RetriedError
    discard_on DiscardedError
    rescue_from(RescuedError) { |ex| } # Do nothing

    def perform(exception = nil)
      raise exception if exception
    end
  end

  def setup
    agent.expects(:queue_job)
    ActiveJob::Base.logger = Logger.new("/dev/null")
  end

  def test_callback
    SampleJob.perform_now
    sections = current_sections_without_gc
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_execution.name)
    assert_equal(1, sections.size)
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob#perform", sections[0].command)
  end

  def test_callback_on_exception
    assert_raises { SampleJob.perform_now("Error") }
    sections = current_sections_without_gc
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_execution.name)
    assert_equal(1, sections.size)
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob#perform", sections[0].command)
    assert_equal(["Error"], agent.current_execution.as_json.dig(:error, :parameters))
  end

  def test_rescued_error_is_ignored
    SampleJob.perform_now(RescuedError)
    refute(agent.current_execution.error, "Rescued error should be ignored")
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_execution.name)
  end

  def test_discarded_error_is_ignored
    SampleJob.perform_now(DiscardedError)
    refute(agent.current_execution.error, "Discarded error should be ignored")
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_execution.name)
  end

  def test_retried_error_ignored
    SampleJob.perform_now(RetriedError)
    refute(agent.current_execution.error, "Retried error should be ignored")
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_execution.name)
  end
end
