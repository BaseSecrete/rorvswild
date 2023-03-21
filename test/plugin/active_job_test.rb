require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveJobTest < Minitest::Test
  include RorVsWild::AgentHelper

  class RescuedError < StandardError; end
  class DiscardError < StandardError; end
  class RetryError < StandardError; end

  class SampleJob < ::ActiveJob::Base
    queue_as :default

    retry_on RetryError
    discard_on DiscardError
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
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_data[:name])
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob#perform", agent.current_data[:sections][0].command)
  end

  def test_callback_on_exception
    assert_raises { SampleJob.perform_now("Error") }
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_data[:name])
    assert_equal(1, agent.current_data[:sections].size)
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob#perform", agent.current_data[:sections][0].command)
    assert_equal(["Error"], agent.current_data[:error][:parameters])
  end

  def test_rescued_error_is_ignored
    SampleJob.perform_now(RescuedError)
    refute(agent.current_data[:error])
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_data[:name])
  end

  def test_discard_error_is_ignored
    SampleJob.perform_now(DiscardError)
    refute(agent.current_data[:error])
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_data[:name])
  end

  def test_retry_error_ignored
    SampleJob.perform_now(RetryError)
    refute(agent.current_data[:error])
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_data[:name])
  end
end

