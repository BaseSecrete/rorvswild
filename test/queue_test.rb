require File.expand_path("#{File.dirname(__FILE__)}/helper")

class QueueTest < Minitest::Test
  include TopTests

  def test_push_job
    queue.thread.expects(:wakeup)
    10.times { queue.push_job(1) }
    assert_equal(10, queue.jobs.size)
  end

  def test_push_request
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

  def test_flush_when_jobs_are_present
    queue.client.expects(:post)
    queue.push_job(1)
    queue.flush
  end

  def test_flush_when_requests_are_present
    queue.client.expects(:post)
    queue.push_request(1)
    queue.flush
  end

  def test_flush_when_empty
    queue.client.expects(:post).never
    queue.flush
  end

  def queue
    @queue ||= RorVsWild::Queue.new(client)
  end

  def client
    @client ||= RorVsWild::Client.new({})
  end
end
