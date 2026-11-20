require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "sidekiq"
require "sidekiq/testing"

class RorVsWild::Plugin::SidekiqTest < Minitest::Test
  include RorVsWild::AgentHelper

  Sidekiq::Testing.server_middleware do |chain|
    chain.add(RorVsWild::Plugin::Sidekiq)
  end

  class SampleJob
    include ::Sidekiq::Worker

    # SampleSidekiqJob.perform_async(1)
    def perform(arg)
      raise "Exception" unless arg
    end
  end

  def test_callback
    agent.expects(:queue_job)
    Sidekiq::Testing.inline! { SampleJob.perform_async(1) }
    assert_equal("RorVsWild::Plugin::SidekiqTest::SampleJob", agent.current_execution.name)
    assert_equal(1, current_user_sections.size)
    assert_equal("RorVsWild::Plugin::SidekiqTest::SampleJob#perform", current_user_sections[0].command)
  end

  def test_callback_on_exception
    agent.expects(:queue_job)
    Sidekiq::Testing.inline! { SampleJob.perform_async(false) }
  rescue
  ensure
    assert_equal([false], agent.current_execution.error.as_json[:parameters])
    sections = current_user_sections
    assert_equal(1, sections.size)
    assert_equal("RorVsWild::Plugin::SidekiqTest::SampleJob#perform", sections[0].command)
    assert(agent.current_execution.runtime > 0)
  end

  def test_attempt
    assert_equal(1, RorVsWild::Plugin::Sidekiq.attempt({"class" => "SampleJob"}))
    assert_equal(2, RorVsWild::Plugin::Sidekiq.attempt({"class" => "SampleJob", "retry_count" => 0}))
    assert_equal(5, RorVsWild::Plugin::Sidekiq.attempt({"class" => "SampleJob", "retry_count" => 3}))
    wrapped = {"class" => "Wrapper", "wrapped" => "SampleJob", "args" => [{"executions" => 2}]}
    assert_equal(3, RorVsWild::Plugin::Sidekiq.attempt(wrapped))
    assert_equal(4, RorVsWild::Plugin::Sidekiq.attempt(wrapped.merge("retry_count" => 0)))
  end

  def test_callback_on_exception_below_attempt_threshold
    agent.config[:job_attempt_threshold] = {"RorVsWild::Plugin::SidekiqTest::SampleJob" => 2}
    agent.expects(:queue_job)
    middleware = RorVsWild::Plugin::Sidekiq.new
    item = {"class" => SampleJob.name, "args" => [false]}
    assert_raises(RuntimeError) { middleware.call(SampleJob.new, item, "default") { SampleJob.new.perform(false) } }
    refute(agent.current_execution.error, "First attempt should not send the error")
  ensure
    agent.config.delete(:job_attempt_threshold)
  end

  def test_callback_on_exception_at_attempt_threshold
    agent.config[:job_attempt_threshold] = {"RorVsWild::Plugin::SidekiqTest::SampleJob" => 2}
    agent.expects(:queue_job)
    middleware = RorVsWild::Plugin::Sidekiq.new
    item = {"class" => SampleJob.name, "args" => [false], "retry_count" => 0}
    assert_raises(RuntimeError) { middleware.call(SampleJob.new, item, "default") { SampleJob.new.perform(false) } }
    assert_equal([false], agent.current_execution.error.as_json[:parameters])
  ensure
    agent.config.delete(:job_attempt_threshold)
  end
end
