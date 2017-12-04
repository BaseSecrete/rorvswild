require "rorvswild/local/middleware"
require "rorvswild/local/queue"

module RorVsWild
  module Local
    def self.start
      Rails.application.config.middleware.use(RorVsWild::Local::Middleware, {})
    end
  end
end
