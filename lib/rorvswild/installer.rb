module RorVsWild
  class Installer
    PATH = "config/rorvswild.yml"

    def self.create_rails_config(api_key)
      if File.directory?("config")
        if !File.exist?(PATH)
          File.write(PATH, template(api_key))
          puts "File #{PATH} has been created. Restart / deploy your app to start collecting data."
        else
          puts "File #{PATH} already exists."
        end
      else
        puts "There is no config directory to create #{PATH}."
      end
    end

    def self.template(api_key)
      <<YAML
production:
  api_key: #{api_key}
  # ignore_requests: # Do not monitor the following actions
  #   - SecretController#index
  # ignore_jobs: # Do not monitor the following jobs
  #   - SecretJob
  # ignore_exceptions: # Do not record the following exceptions
  #   - ActionController::RoutingError  # By default to ignore 404
  # ignore_plugins:
  #   - ActionController
  #   - ActionMailer
  #   - ActionView
  #   - ActiveJob
  #   - ActiveRecord
  #   - DelayedJob
  #   - Elasticsearch
  #   - Mongo
  #   - NetHttp
  #   - Redis
  #   - Resque
  #   - Sidekiq
  # logger: log/rorvswild.log # By default it uses Rails.logger or Logger.new(STDOUT)
  # # Deployment tracking is working without any actions from your part if the Rails app
  # # is inside a Git repositoriy, is deployed via Capistrano.
  # # In the other cases, you can provide the following details.
  # deployment:
  #   revision: <%= "Anything that will return the deployment version" %> # Mandatory
  #   description: <%= "Eventually if you have a description such as a Git message" %>
  #   author: <%= "Author's name of the deployment" %>
    #   email: <%= "emailOf@theAuthor.com" %>
YAML
    end
  end
end
