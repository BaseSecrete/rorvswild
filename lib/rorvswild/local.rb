require "rorvswild/local/middleware"
require "rorvswild/local/queue"

module RorVsWild
  module Local
    def self.start(config = {})
      RorVsWild.start(config.merge(queue: RorVsWild::Local::Queue.new))
      Rails.application.config.middleware.unshift(RorVsWild::Local::Middleware, nil)
    end
  end
end
