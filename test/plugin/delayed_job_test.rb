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
    attr_accessor :handler
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
end
