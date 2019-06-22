module RorVsWild
  class Installer
    PATH = "config/rorvswild.yml"

    def self.create_rails_config(api_key)
      if File.directory?("config")
        if !File.exists?(PATH)
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
    # ignore_actions: # Do not track following endpoints
    #   - SecretController#index
    # ignore_jobs: # Do not monitor the following jobs
    #   - SecretJob
    # ignore_exceptions: # Do not track following exceptions
    #   - ActionController::RoutingError
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
YAML
    end
  end
end
