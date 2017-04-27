module RorVsWild
  module Location
    def extract_most_relevant_file_and_line(locations)
      location = find_most_relevant_location(locations)
      [relative_path(location.path), location.lineno]
    end

    def find_most_relevant_location(locations)
      result = locations.find { |l| l.path.index(app_root) == 0 && !(l.path =~ gem_home_regex) } if app_root
      result || locations.find { |l| !(l.path =~ gem_home_regex) } || locations.first
    end

    def extract_most_relevant_file_and_line_from_exception(exception)
      # Exception#backtrace_locations is faster but exists since 2.1.0.
      # Sometime Exception#backtrace_locations returns nil for an unknow reason. So we fallback to the old way.
      if exception.respond_to?(:backtrace_locations) && locations = exception.backtrace_locations
        extract_most_relevant_file_and_line(locations)
      elsif backtrace = exception.backtrace
        extract_most_relevant_file_and_line_from_array_of_strings(backtrace)
      else
        ["No backtrace".freeze, 1]
      end
    end

    def extract_most_relevant_file_and_line_from_array_of_strings(stack)
      location = stack.find { |str| str =~ app_root_regex && !(str =~ gem_home_regex) } if app_root_regex
      location ||= stack.find { |str| !(str =~ gem_home_regex) } if gem_home_regex
      relative_path(location || stack.first).split(":".freeze)
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
