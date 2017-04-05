module RorVsWild
  module Location
    def extract_most_relevant_location(stack)
      location = stack.find { |l| l.path.index(app_root) == 0 && !(l.path =~ gem_home_regex) } if app_root
      location ||= stack.find { |l| !(l.path =~ gem_home_regex) } || stack.first
      [relative_path(location.path), location.lineno]
    end

    def gem_home_regex
      @gem_home_regex ||= gem_home ? /\A#{gem_home}/.freeze : /\/gems\//.freeze
    end

    def gem_home
      @gem_home ||= guess_gem_home
    end

    def guess_gem_home
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
