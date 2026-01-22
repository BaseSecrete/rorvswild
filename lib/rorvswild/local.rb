require "rorvswild/local/middleware"
require "rorvswild/local/queue"

module RorVsWild
  module Local
    def self.start(config = {})
      queue = RorVsWild::Local::Queue.new(config[:queue] || {})
      RorVsWild.start(config.merge(queue: queue))
      Rails.application.config.middleware.unshift(RorVsWild::Local::Middleware, config)
    end
  end
end
