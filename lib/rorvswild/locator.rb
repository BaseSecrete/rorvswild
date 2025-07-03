module RorVsWild
  class Locator
    attr_reader :current_path

    def initialize(current_path = Dir.pwd)
      @current_path = File.join(current_path, "")
    end

    def find_most_relevant_file_and_line(locations)
      location = find_most_relevant_location(locations)
      [relative_path(location.path), location.lineno]
    end

    def find_most_relevant_location(locations)
      locations.find { |l| l.path && relevant_path?(l.path) } ||
        locations.find { |l| l.path && !l.path.start_with?(rorvswild_lib_path) } ||
        locations.first
    end

    def find_most_relevant_file_and_line_from_exception(exception)
      # Exception#backtrace_locations is faster but exists since 2.1.0.
      # Sometime Exception#backtrace_locations returns nil for an unknow reason. So we fallback to the old way.
      if exception.respond_to?(:backtrace_locations) && locations = exception.backtrace_locations
        find_most_relevant_file_and_line(locations)
      elsif (backtrace = exception.backtrace) && backtrace.size > 0
        find_most_relevant_file_and_line_from_array_of_strings(backtrace)
      else
        ["No backtrace".freeze, 1]
      end
    end

    def find_most_relevant_file_and_line_from_array_of_strings(stack)
      location = stack.find { |str| relevant_path?(str) }
      location ||= stack.find { |str| !str.start_with?(rorvswild_lib_path) }
      relative_path(location || stack.first).split(":".freeze)
    end

    def relative_path(path)
      path.start_with?(current_path) ? path.sub(current_path, "".freeze) : path
    end

    def relevant_path?(path)
      path.start_with?(current_path) && !irrelevant_path?(path)
    end

    def irrelevant_path?(path)
      path.start_with?(*lib_paths)
    end

    def lib_paths
      @lib_paths ||= initialize_lib_paths
    end

    def rorvswild_lib_path
      @rorvswild_lib_path ||= File.dirname(File.expand_path(__FILE__))
    end

    private

    def initialize_lib_paths
      array = [RbConfig::CONFIG["rubylibprefix"]] + Gem.default_path + Gem.path
      array += ["RUBYLIB", "GEM_HOME", "GEM_PATH", "BUNDLER_ORIG_GEM_PATH"].flat_map do |name|
        ENV[name].split(":".freeze) if ENV[name]
      end
      array.compact.uniq
    end
  end
end
