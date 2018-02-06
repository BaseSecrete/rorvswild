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

  Delayed::Worker.delay_jobs = false

  class SampleBackend
    include Delayed::Backend::Base

    attr_accessor :handler

    def initialize(options)
      @payload_object = options[:payload_object]
    end
  end

  def test_callback
    agent.expects(:post_job)
    SampleBackend.enqueue(SampleJob.new(true))
    assert_equal("RorVsWild::Plugin::DelayedJobTest::SampleJob", agent.data[:name])
  end

  def test_callback_on_exception
    agent.expects(:post_job)
    SampleBackend.enqueue(job = SampleJob.new(false))
  rescue
  ensure
    assert_equal(job, agent.data[:error][:parameters])
  end
end

