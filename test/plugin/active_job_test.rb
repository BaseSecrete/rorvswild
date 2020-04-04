require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveJobTest < Minitest::Test
  include RorVsWild::AgentHelper

  class SampleJob < ::ActiveJob::Base
    queue_as :default

    def perform(arg)
      raise "Exception" unless arg
    end
  end

  def test_callback
    ActiveJob::Base.logger = Logger.new("/dev/null")
    agent.expects(:post_job)
    SampleJob.perform_now(1)
    assert_equal("RorVsWild::Plugin::ActiveJobTest::SampleJob", agent.current_data[:name])
  end

  def test_callback_on_exception
    ActiveJob::Base.logger = Logger.new("/dev/null")
    agent.expects(:post_job)
    SampleJob.perform_now(false)
  rescue
  ensure
    assert_equal([false], agent.current_data[:error][:parameters])
  end
end

