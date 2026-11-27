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
    payload = sample_payload

    Faktory.worker_middleware.invoke(job, payload) { job.perform(*payload["args"]) }
    assert_equal(SampleFaktoryJob.name, agent.current_execution.name)
  end

  def test_callback_on_exception
    agent.expects(:queue_job)
    Faktory.worker_middleware.add(RorVsWild::Plugin::Faktory)

    job = SampleFaktoryJob.new
    payload = sample_payload("args" => [false])

    Faktory.worker_middleware.invoke(job, payload) { job.perform(*payload["args"]) }
  rescue
  ensure
    assert_equal([false], agent.current_execution.error.as_json[:parameters])
  end

  def test_attempt_threshold_mutes_early_retries
    @agent = initialize_agent(job_attempt_threshold: {SampleFaktoryJob.name => 3})
    agent.expects(:queue_job)
    Faktory.worker_middleware.add(RorVsWild::Plugin::Faktory)

    job = SampleFaktoryJob.new
    payload = sample_payload("args" => [false], "failure" => {"retry_count" => 0})

    assert_raises { Faktory.worker_middleware.invoke(job, payload) { job.perform(*payload["args"]) } }
    refute(agent.current_execution.error)
  end

  def test_attempt_threshold_reports_when_reached
    @agent = initialize_agent(job_attempt_threshold: {SampleFaktoryJob.name => 3})
    agent.expects(:queue_job)
    Faktory.worker_middleware.add(RorVsWild::Plugin::Faktory)

    job = SampleFaktoryJob.new
    payload = sample_payload("args" => [false], "failure" => {"retry_count" => 1})

    assert_raises { Faktory.worker_middleware.invoke(job, payload) { job.perform(*payload["args"]) } }
    assert(agent.current_execution.error)
  end

  private

  def sample_payload(overrides = {})
    {
      "jid" => "e659ba0aab6684207e590af5",
      "queue" => "default",
      "jobtype" => SampleFaktoryJob.name,
      "args" => [123],
      "created_at" => "2020-01-23T10:30:48.329616897Z",
      "enqueued_at" => "2020-01-23T10:30:48.329716652Z",
      "retry" => 5,
    }.merge(overrides)
  end
end
