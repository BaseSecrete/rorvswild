# frozen_string_literal: true

module RorVsWild
  module Deployment
    def self.load_config(config)
      read
      if hash = config[:deployment]
        @description = hash[:description]
        @revision = hash[:revision]
        @author = hash[:author]
        @email = hash[:email]
      end
    end

    def self.revision
      @revision
    end

    def self.description
      @description
    end

    def self.author
      @author
    end

    def self.email
      @email
    end

    def self.ruby
      RUBY_VERSION
    end

    def self.rails
      Rails.version if defined?(Rails)
    end

    def self.rorvswild
      RorVsWild::VERSION
    end

    def self.to_h
      @to_h ||= {revision: revision, description: description, author: author, email: email, ruby: ruby, rails: rails, rorvswild: rorvswild}.compact
    end

    def self.read
      read_from_heroku || read_from_scalingo || read_from_git || read_from_capistrano
    end

    private

    def self.read_from_heroku
      return unless ENV["HEROKU_SLUG_COMMIT"]
      @revision = ENV["HEROKU_SLUG_COMMIT"]
      @description = ENV["HEROKU_SLUG_DESCRIPTION"]
    end

    def self.read_from_scalingo
      return unless ENV["SOURCE_VERSION"]
      @revision = ENV["SOURCE_VERSION"]
    end

    def self.read_from_git
      @revision = normalize_string(`git rev-parse HEAD`) rescue nil
      return unless @revision
      lines = `git log -1 --pretty=%an%n%ae%n%B`.lines rescue nil
      return unless lines
      @author = normalize_string(lines[0])
      @email = normalize_string(lines[1])
      @description = lines[2..-1] && normalize_string(lines[2..-1].join)
      @revision
    end

    def self.read_from_capistrano
      return unless File.readable?("REVISION")
      return unless @revision = File.read("REVISION")
      lines = `git --git-dir ../../repo log --format=%an%n%ae%n%B -n 1 #{@revision}`.lines rescue nil
      return unless lines
      @author = normalize_string(lines[0])
      @email = normalize_string(lines[1])
      @description = lines[2..-1] && normalize_string(lines[2..-1].join)
      @revision
    end

    def self.normalize_string(string)
      if string
        string = string.strip
        string.empty? ? nil : string
      end
    end
  end
end
