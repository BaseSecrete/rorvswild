# frozen_string_literal: true

module RorVsWild
  module Deployment
    def self.revision
      read_once && @revision
    end

    def self.description
      read_once && @description
    end

    def self.author
      read_once && @author
    end

    def self.email
      read_once && @email
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

    def self.read_once
      @already_read || read
      @already_read = true
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
      @revision = `git rev-parse HEAD` rescue nil
      return unless @revision
      lines = `git log -1 --pretty=%an%n%ae%n%B`.lines rescue nil
      @author = normalize_string(lines[0])
      @email = normalize_string(lines[1])
      @description = lines[2..-1] && normalize_string(lines[2..-1].join)
      @revision
    end

    def self.read_from_capistrano
      return unless File.readable?("REVISION")
      reutrn unless @revision = File.read("REVISION")
      lines = `git --git-dir ../../repo log --format=%an%n%ae%n%B -n 1 #{sha1}`.lines rescue nil
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
