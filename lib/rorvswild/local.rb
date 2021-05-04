require "rorvswild/local/middleware"
require "rorvswild/local/queue"

module RorVsWild
  module Local
    def self.start(config)
      Rails.application.config.middleware.unshift(RorVsWild::Local::Middleware, nil)
      RorVsWild.start(config.merge(queue: RorVsWild::Local::Queue.new))
    end
  end
end
