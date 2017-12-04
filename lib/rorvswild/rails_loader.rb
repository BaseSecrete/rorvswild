module RorVsWild
  class RailsLoader
    def self.start_on_rails_initialization
      return if !defined?(Rails)
      Rails::Railtie.initializer "rorvswild.detect_config_file" do
        RorVsWild::RailsLoader.start
      end
    end

    def self.start
      return if RorVsWild.agent

      if (path = Rails.root.join("config/rorvswild.yml")).exist?
        if config = RorVsWild::RailsLoader.load_config_file(path)[Rails.env]
          RorVsWild.start(config.symbolize_keys)
        end
      end

      if !RorVsWild.agent && Rails.env.development?
        require "rorvswild/local"
        RorVsWild::Local.start
      end
    end

    def self.load_config_file(path)
      YAML.load(ERB.new(path.read).result)
    end
  end
end
