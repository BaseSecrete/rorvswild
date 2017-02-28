require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveJobTest < Minitest::Test
  class SampleJob < ::ActiveJob::Base
    queue_as :default

    def perform
    end
  end

  def test_callback
    ActiveJob::Base.logger = Logger.new("/dev/null")
    client.expects(:post_job)
    SampleJob.perform_now
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

