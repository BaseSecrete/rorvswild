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
    assert_equal("RorVsWild::Plugin::SidekiqTest::SampleJob", agent.current_data[:name])
  end

  def test_callback_on_exception
    agent.expects(:queue_job)
    Sidekiq::Testing.inline! { SampleJob.perform_async(false) }
  rescue
  ensure
    assert_equal([false], agent.current_data[:error].as_json[:parameters])
  end
end

