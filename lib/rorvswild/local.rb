require "rorvswild/local/middleware"
require "rorvswild/local/queue"

module RorVsWild
  module Local
    def self.start
      Rails.application.config.middleware.unshift(RorVsWild::Local::Middleware, nil)
      RorVsWild.start(queue: RorVsWild::Local::Queue.new)
    end
  end
end
