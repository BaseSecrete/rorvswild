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
development:
  # Widget position
  # widget: top-left, top-right, bottom-left, bottom-right or hidden

  # Open files in your text editor by clicking from the local widget.
  # VSCode: vscode://file${path}:${line}
  # Sublime: subl://${path}:${line}
  # It should be set with an env variable when developers are not using the same editor.
  editor_url: <%= ENV.fetch("RORVSWILD_EDITOR_URL", "vscode://file${path}:${line}") %>

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
  #
  # logger: log/rorvswild.log # By default it uses Rails.logger or Logger.new(STDOUT)
  #
  # # Deployment tracking is working without any actions from your part if the Rails app
  # # is inside a Git repository, is deployed via Capistrano.
  # # In the other cases, you can provide the following details.
  # deployment:
  #   revision: <%= "Anything that will return the deployment version" %> # Mandatory
  #   description: <%= "Eventually if you have a description such as a Git message" %>
  #   author: <%= "Author's name of the deployment" %>
  #   email: <%= "emailOf@theAuthor.example" %>
  #
  # Sampling allows to send a fraction of jobs and requests.
  # If your app is sending hundred of millions of requests per month,
  # you will probably get the same precision if you send only a fraction of it.
  # Thus, it decreases the bill at the end of the month. It's also a mitigation if
  # your app is a target of a DoS. There are 2 parameters to dissociate requests and jobs.
  # Indeed, for an app handling a lot of request but very few jobs, it makes sens to sample
  # the former but not the latter.
  # request_sampling_rate: 0.25 # 25% of requests are sent
  # job_sampling_rate: 0.5 # 50% of jobs are sent
YAML
    end
  end
end
