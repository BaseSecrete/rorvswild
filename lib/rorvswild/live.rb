require "rorvswild/live/middleware"
require "rorvswild/live/queue"

module RorVsWild
  module Live
    def self.start
      Rails.application.config.middleware.use(RorVsWild::Live::Middleware, {})
    end
  end
end
