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
      revision = revision_from_scalingo || revision_from_heroku || revision_from_git || revision_from_capistrano
      @revision = revision && revision.strip
    end

    def self.revision_description
      return @revision_description if defined?(@revision_description)
      revision_description = revision_description_from_heroku || revision_description_from_git || revision_description_from_capistrano
      @revision_description = revision_description && revision_description.strip
    end

    def self.to_h
      @to_h ||= {os: os, user: user, host: name, ruby: ruby, pid: pid, cwd: cwd, revision: revision, revision_description: revision_description}
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
      sha1 = `git rev-parse HEAD`.strip rescue nil
      sha1 if !sha1.empty?
    end

    def self.revision_description_from_heroku
      ENV["HEROKU_SLUG_DESCRIPTION"]
    end

    def self.revision_description_from_git
      msg = `git log -1 --pretty=%B`.strip rescue nil
      msg if !msg.empty?
    end

    def self.revision_description_from_capistrano
      if sha1 = revision_from_git
        msg = `git --git-dir ../../repo log --format=%B -n 1 #{sha1}` rescue nil
        msg if msg && !msg.strip.empty?
      end
    end
  end
end
