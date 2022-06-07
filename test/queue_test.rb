require File.expand_path("#{File.dirname(__FILE__)}/helper")

class RorVsWild::QueueTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_push_job
    queue.start_thread
    queue.thread.expects(:wakeup)
    10.times { queue.push_job(1) }
    assert_equal(10, queue.jobs.size)
  end

  def test_push_request
    queue.start_thread
    queue.thread.expects(:wakeup)
    10.times { queue.push_request(1) }
    assert_equal(10, queue.requests.size)
  end

  def test_pull_jobs
    queue.push_job(1)
    assert_equal([1], queue.pull_jobs)
    refute(queue.pull_jobs)
  end

  def test_pull_requests
    queue.push_request(1)
    assert_equal([1], queue.pull_requests)
    refute(queue.pull_requests)
  end

  def test_pull_server_metrics
    assert_kind_of(Hash, queue.pull_server_metrics)
    refute(queue.pull_server_metrics)
  end

  def test_flush_when_jobs_are_present
    queue.stubs(:pull_server_metrics)
    queue.client.expects(:post)
    queue.push_job(1)
    queue.flush
  end

  def test_flush_when_requests_are_present
    queue.stubs(:pull_server_metrics)
    queue.client.expects(:post)
    queue.push_request(1)
    queue.flush
  end

  def test_flush_when_there_are_metrics
    queue.client.expects(:post)
    queue.flush
  end

  def test_flush_when_empty
    queue.stubs(:pull_server_metrics)
    queue.client.expects(:post).never
    queue.flush
  end

  def queue
    @queue ||= agent.instance_variable_get(:@queue)
  end

  def client
    @client ||= agent.instance_variable_get(:@client)
  end
end
