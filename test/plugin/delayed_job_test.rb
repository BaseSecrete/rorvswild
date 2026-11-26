# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "delayed_job"

class RorVsWild::Plugin::DelayedJobTest < Minitest::Test
  include RorVsWild::AgentHelper

  class SampleJob
    def initialize(arg)
      @arg = arg
    end

    def perform
      raise "Exception" unless @arg
    end
  end

  class SampleBackend
    include Delayed::Backend::Base
    attr_accessor :handler, :attempts

    def initialize
      @attempts = 0
    end
  end

  def test_callback
    agent.expects(:queue_job)
    backend = SampleBackend.new
    backend.payload_object = SampleJob.new(true)
    backend.invoke_job
    assert_equal("RorVsWild::Plugin::DelayedJobTest::SampleJob", agent.current_execution.name)
  end

  def test_callback_on_exception
    agent.expects(:queue_job)
    backend = SampleBackend.new
    backend.payload_object = job = SampleJob.new(false)
    backend.invoke_job
  rescue
  ensure
    assert_equal(job, agent.current_execution.error.as_json[:parameters])
  end

  def test_attempt_threshold_mutes_early_retries
    @agent = initialize_agent(job_attempt_threshold: {SampleJob.name => 3})
    agent.expects(:queue_job)
    backend = SampleBackend.new
    backend.attempts = 1
    backend.payload_object = SampleJob.new(false)
    assert_raises { backend.invoke_job }
    refute(agent.current_execution.error)
  end

  def test_attempt_threshold_reports_when_reached
    @agent = initialize_agent(job_attempt_threshold: {SampleJob.name => 3})
    agent.expects(:queue_job)
    backend = SampleBackend.new
    backend.attempts = 2
    backend.payload_object = SampleJob.new(false)
    assert_raises { backend.invoke_job }
    assert(agent.current_execution.error)
  end
end
