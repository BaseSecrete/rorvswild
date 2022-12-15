require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "resque"

class RorVsWild::Plugin::ResqueTest < Minitest::Test
  include RorVsWild::AgentHelper

  Resque.inline = true

  class SampleJob < Resque::Job
    @queue = :default

    def self.perform(arg)
      raise "Exception" unless arg
    end
  end

  def test_callback
    agent.expects(:queue_job)
    Resque.enqueue(SampleJob, true)
    assert_equal("RorVsWild::Plugin::ResqueTest::SampleJob", agent.current_data[:name])
  end

  def test_callback_on_exception
    agent.expects(:queue_job)
    Resque.enqueue(SampleJob, false)
  rescue
  ensure
    assert_equal([false], agent.current_data[:error][:parameters])
  end
end

