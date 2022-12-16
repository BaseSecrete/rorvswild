# frozen_string_literal: true

module RorVsWild
  module Host
    def self.os
      @os_description ||= `uname -sr`.strip
    rescue Exception => ex
      @os_description = RbConfig::CONFIG["host_os"]
    end

    def self.user
      Etc.getlogin
    end

    def self.ruby
      RUBY_DESCRIPTION
    end

    def self.rails
      Rails.version if defined?(Rails)
    end

    def self.name
      if gae_instance = ENV["GAE_INSTANCE"] || ENV["CLOUD_RUN_EXECUTION"]
        gae_instance
      elsif dyno = ENV["DYNO"] # Heroku
        dyno.start_with?("run.") ? "run.*" :
          dyno.start_with?("release.") ? "release.*" : dyno
      else
        Socket.gethostname
      end
    end

    def self.pid
      Process.pid
    end

    def self.cwd
      Dir.pwd
    end

    def self.revision
      Deployment.revision
    end

    def self.revision_description
      Deployment.description
    end

    def self.to_h
      @to_h ||= {os: os, user: user, host: name, ruby: ruby, rails: rails, pid: pid, cwd: cwd, revision: revision}.compact
    end
  end
end
