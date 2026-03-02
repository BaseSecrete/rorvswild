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
  # Leave commented to auto-detect from RAILS_EDITOR or EDITOR env vars (Rails 8.1+).
  # Or set explicitly:
  # editor_url: <%= ENV.fetch("RORVSWILD_EDITOR_URL", "vscode://file${path}:${line}") %>
  # for VSCode: "vscode://file${path}:${line}"
  # for Sublime: "subl://${path}:${line}"

production:
  api_key: <%= ENV["RORVSWILD_API_KEY"] || "#{api_key}" %>

  # Do not monitor the following actions.
  ignore_requests:
   - SecretController#index

  # Do not monitor the following jobs.
  ignore_jobs:
    - SecretJob

  # Do not monitor the following exceptions.
  ignore_exceptions:
    # Noisy exceptions such as ActionNotFound, UnknownHttpMethod, etc are ignored by default.
    - <%= ActionDispatch::ExceptionWrapper.rescue_responses.keys.join("\\n    - ") %>
    - AnotherNoisyError

  # In case you want less details.
  ignore_plugins:
    # - ActionController
    # - ActionMailer
    # - ActionView
    # - ActiveJob
    # - ActiveRecord
    # - DelayedJob
    # - Elasticsearch
    # - Faktory
    # - Mongo
    # - NetHttp
    # - Rack
    # - RailsCache
    # - RailsError
    # - Redis
    # - Resque
    # - Sidekiq

  # logger: log/rorvswild.log # By default it uses Rails.logger or Logger.new(STDOUT)

  # Deployment tracking is working without any actions from your part if the Rails app
  # is inside a Git repository, or deployed with Capistrano, Kamal, Heroku or Scalingo.
  # In the other cases, you can provide the following details.
  # deployment:
  #   revision: <%= "Anything that will return the deployment version" %> # Mandatory
  #   description: <%= "Eventually if you have a description such as a Git message" %>
  #   author: <%= "Author's name of the deployment" %>
  #   email: <%= "emailOf@theAuthor.example" %>

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
