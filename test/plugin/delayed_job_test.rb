require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "delayed_job"

class RorVsWild::Plugin::DelayedJobTest < Minitest::Test
  include RorVsWildAgentHelper

  class SampleJob
    def perform
    end
  end

  class SampleBackend
    include Delayed::Backend::Base

    attr_accessor :id,  :attempts

    def initialize(options)
    end

    def payload_object
      SampleJob.new
    end

    def destroy
    end
  end

  def test_callback
    agent.expects(:post_job)
    Delayed::Worker.delay_jobs = false
    SampleBackend.enqueue(SampleJob.new)
  end
end

