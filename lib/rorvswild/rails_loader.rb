module RorVsWild
  class RailsLoader
    @started = false

    def self.start_on_rails_initialization
      return if !defined?(Rails)
      Rails::Railtie.initializer "rorvswild.detect_config_file" do
        RorVsWild::RailsLoader.start
      end
    end

    def self.start
      return if @started
      if (path = Rails.root.join("config/rorvswild.yml")).exist?
        if config = RorVsWild::RailsLoader.load_config_file(path)[Rails.env]
          RorVsWild::Client.new(config.symbolize_keys)
          @started = true
        end
      end
    end

    def self.load_config_file(path)
      YAML.load(ERB.new(path.read).result)
    end
  end
end
