require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "active_job"

class RorVsWild::Plugin::ActiveJobTest < Minitest::Test
  include RorVsWildClientHelper

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
end

