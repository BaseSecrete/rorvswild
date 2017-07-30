require File.expand_path("#{File.dirname(__FILE__)}/helper")

class QueueTest < Minitest::Test
  include TopTests

  def test_push_job
    queue.thread.expects(:wakeup)
    10.times { queue.push_job(1) }
    assert_equal(10, queue.jobs.size)
  end

  def test_pull_job
    queue.push_job(1)
    assert_equal([1], queue.pull_jobs)
    refute(queue.pull_jobs)
  end

  def test_flush
    queue.client.expects(:post)
    queue.push_job(1)
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
