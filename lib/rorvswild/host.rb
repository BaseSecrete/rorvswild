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
      return @revision if defined?(@revision)
      @revision = normalize_string(revision_from_scalingo) ||
        normalize_string(revision_from_heroku) ||
        normalize_string(revision_from_git) ||
        normalize_string(revision_from_capistrano)
    end

    def self.revision_description
      return @revision_description if defined?(@revision_description)
      @revision_description = normalize_string(revision_description_from_heroku) ||
        normalize_string(revision_description_from_git) ||
        normalize_string(revision_description_from_capistrano)
    end

    def self.to_h
      @to_h ||= {os: os, user: user, host: name, ruby: ruby, rails: rails, pid: pid, cwd: cwd, revision: revision}.compact
    end

    private

    def self.revision_from_heroku
      ENV["HEROKU_SLUG_COMMIT"]
    end

    def self.revision_from_scalingo
      ENV["SOURCE_VERSION"]
    end

    def self.revision_from_capistrano
      File.read("REVISION") if File.readable?("REVISION")
    end

    def self.revision_from_git
      `git rev-parse HEAD` rescue nil
    end

    def self.revision_description_from_heroku
      ENV["HEROKU_SLUG_DESCRIPTION"]
    end

    def self.revision_description_from_git
      msg = `git log -1 --pretty=%B` rescue nil
    end

    def self.revision_description_from_capistrano
      if sha1 = revision_from_git
        `git --git-dir ../../repo log --format=%B -n 1 #{sha1}` rescue nil
      end
    end

    def self.normalize_string(string)
      if string
        string = string.strip
        string.empty? ? nil : string
      end
    end
  end
end
