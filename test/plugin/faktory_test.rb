require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "faktory"

class RorVsWild::Plugin::FaktoryTest < Minitest::Test
  include RorVsWild::AgentHelper

  class SampleFaktoryJob
    include Faktory::Job

    def perform(args)
      raise unless args
    end
  end

  def test_callback
    agent.expects(:queue_job)
    Faktory.worker_middleware.add(RorVsWild::Plugin::Faktory)

    job = SampleFaktoryJob.new
    payload = {
      "jid" => "e659ba0aab6684207e590af5",
      "queue" => "default",
      "jobtype" => "RorVsWild::Plugin::FaktoryTest::SampleFaktoryJob",
      "args" => [123],
      "created_at" => "2020-01-23T10:30:48.329616897Z",
      "enqueued_at" => "2020-01-23T10:30:48.329716652Z",
      "retry" => 5,
    }

    Faktory.worker_middleware.invoke(job, payload) { job.perform(*payload["args"]) }
    assert_equal("RorVsWild::Plugin::FaktoryTest::SampleFaktoryJob", agent.current_data[:name])
  end

  def test_callback_on_exception
    agent.expects(:queue_job)
    Faktory.worker_middleware.add(RorVsWild::Plugin::Faktory)

    job = SampleFaktoryJob.new
    payload = {
      "jid" => "e659ba0aab6684207e590af5",
      "queue" => "default",
      "jobtype" => "RorVsWild::Plugin::FaktoryTest::SampleFaktoryJob",
      "args" => [false],
      "created_at" => "2020-01-23T10:30:48.329616897Z",
      "enqueued_at" => "2020-01-23T10:30:48.329716652Z",
      "retry" => 5,
    }

    Faktory.worker_middleware.invoke(job, payload) { job.perform(*payload["args"]) }
  rescue
  ensure
    assert_equal([false], agent.current_data[:error][:parameters])
  end
end

