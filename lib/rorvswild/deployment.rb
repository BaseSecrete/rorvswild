# frozen_string_literal: true

require "open3"

module RorVsWild
  module Deployment
    @revision = @description = @author = @email = nil

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
      Rails.version if defined?(Rails) && Rails.respond_to?(:version)
    end

    def self.rorvswild
      RorVsWild::VERSION
    end

    def self.to_h
      @to_h ||= {revision: revision, description: description, author: author, email: email, ruby: ruby, rails: rails, rorvswild: rorvswild}.compact
    end

    def self.read
      read_from_heroku || read_from_scalingo || read_from_kamal || read_from_git || read_from_capistrano
    end

    private

    def self.read_from_heroku
      return unless ENV["HEROKU_SLUG_COMMIT"]
      @revision = ENV["HEROKU_SLUG_COMMIT"]
      @description = ENV["HEROKU_SLUG_DESCRIPTION"]
    end

    def self.read_from_scalingo
      @revision = ENV["CONTAINER_VERSION"] || ENV["SOURCE_VERSION"]
    end

    def self.read_from_git
      return unless @revision = normalize_string(shell("git rev-parse HEAD"))
      return @revision unless log_stdout = shell("git log -1 --pretty=%an%n%ae%n%B")
      parse_git_log(log_stdout.lines)
      @revision
    end

    def self.read_from_capistrano
      return unless File.readable?("REVISION")
      return unless @revision = File.read("REVISION")
      return unless stdout = shell("git --git-dir ../../repo log --format=%an%n%ae%n%B -n 1 #{@revision}")
      parse_git_log(stdout.lines)
      @revision
    end

    def self.read_from_kamal
      return unless ENV["KAMAL_VERSION"]
      @revision = ENV["KAMAL_VERSION"]
    end

    def self.normalize_string(string)
      if string
        string = string.strip
        string.empty? ? nil : string
      end
    end

    def self.shell(command)
      stdout, _, process = Open3.capture3(command) rescue nil
      stdout if process && process.success?
    end

    def self.parse_git_log(lines)
      @author = normalize_string(lines[0])
      @email = normalize_string(lines[1])
      @description = lines[2..-1] && normalize_string(lines[2..-1].join)
    end
  end
end
