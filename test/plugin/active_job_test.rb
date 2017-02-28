require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveTest < Minitest::Test
  class SampleActiveJob< ::ActiveJob::Base
    queue_as :default

    def perform
    end
  end

  def test_callback
    ActiveJob::Base.logger = Logger.new("/dev/null")
    client.expects(:post_job)
    SampleActiveJob.perform_now
  end

  private

  def client
    @client ||= initialize_client(app_root: "/rails/root")
  end

  def initialize_client(options = {})
    client ||= RorVsWild::Client.new(options)
    client.stubs(:post_request)
    client.stubs(:post_job)
    client
  end
end

