module RorVsWild
  module Location
    def self.cleanup_method_name(method)
      method.sub!("block in ".freeze, "".freeze)
      method.sub!("in `".freeze, "".freeze)
      method.sub!("'".freeze, "".freeze)
      method.index("_app_views_".freeze) == 0 ? nil : method
    end

    def self.split_file_location(location)
      file, line, method = location.split(":")
      method = cleanup_method_name(method) if method
      [file, line, method]
    end

    def extract_most_relevant_location(stack)
      location = stack.find { |str| str =~ app_root_regex && !(str =~ gem_home_regex) } if app_root_regex
      location ||= stack.find { |str| !(str =~ gem_home_regex) } if gem_home_regex
      RorVsWild::Location.split_file_location(relative_path(location || stack.first))
    end

    def app_root_regex
      @app_root_regex ||= RorVsWild.default_client.app_root ? /\A#{RorVsWild.default_client.app_root}/ : nil
    end

    def gem_home_regex
      @gem_home_regex ||= gem_home ? /\A#{gem_home}/.freeze : /\/gems\//.freeze
    end

    def gem_home
      if ENV["GEM_HOME"] && !ENV["GEM_HOME"].empty?
        ENV["GEM_HOME"]
      elsif ENV["GEM_PATH"] && !(first_gem_path = ENV["GEM_PATH"].split(":").first)
        first_gem_path if first_gem_path && !first_gem_path.empty?
      end
    end

    def relative_path(path)
      app_root_regex ? path.sub(app_root_regex, "".freeze) : path
    end
  end
end
