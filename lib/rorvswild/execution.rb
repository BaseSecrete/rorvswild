# frozen_string_literal: true

module RorVsWild
  class Execution
    attr_reader :parameters, :sections, :section_stack, :error_context, :runtime

    attr_accessor :error, :name

    def initialize(name, parameters)
      @name = name
      @parameters = parameters
      @runtime = nil
      @error = nil
      @error_context = nil

      @started_at = RorVsWild.clock_milliseconds
      @gc_section = Section.start_gc_timing
      @environment = Host.to_h
      @section_stack = []
      @sections = []
    end

    def add_section(section)
      if sibling = @sections.find { |s| s.sibling?(section) }
        sibling.merge(section)
      else
        @sections << section
      end
    end

    def add_queue_time(queue_time_ms)
      return unless queue_time_ms
      @started_at -= queue_time_ms
      section = Section.new
      section.total_ms = queue_time_ms
      section.gc_time_ms = 0
      section.file = "queue"
      section.line = 0
      section.kind = "queue"
      add_section(section)
    end

    def stop
      Section.stop_gc_timing(@gc_section)
      @sections << @gc_section if @gc_section.calls > 0 && @gc_section.total_ms > 0
      @runtime = RorVsWild.clock_milliseconds - @started_at
    end

    def as_json(options = nil)
      {
        name: name,
        runtime: @runtime,
        error: @error && @error.as_json(options),
        sections: @sections.map(&:as_json),
        environment: Host.to_h,
      }
    end

    def add_exception(exception)
      @error = Error.new(exception) if !RorVsWild.agent.ignored_exception?(exception) && !@error
    end

    def merge_error_context(hash)
      @error_context = @error_context ? @error_context.merge(hash) : hash
    end

    private

    def start_gc_timing
      section = Section.new
      section.calls = GC.count
      section.file, section.line = "ruby/gc.c", 0
      section.add_command("GC.start")
      section.kind = "gc"
      section
    end

    if GC.respond_to?(:total_time)
      def gc_total_ms
        GC.total_time / 1_000_000.0 # nanosecond -> millisecond
      end
    else
      def gc_total_ms
        GC::Profiler.total_time * 1000 # second -> millisecond
      end
    end

    class Job < Execution
      def add_exception(exception)
        super(exception)
        @error && @error.details = {parameters: parameters, job: {name: name}}
        @error
      end
    end

    class Request < Execution
      attr_reader :path

      attr_accessor :controller

      def initialize(path)
        @path = path
        super(nil, nil)
      end

      def add_exception(exception)
        super(exception)
        @error && @error.details = {
          parameters: controller.request.filtered_parameters,
          request: {
            headers: headers,
            name: "#{controller.class}##{controller.action_name}",
            method: controller.request.method,
            url: controller.request.url,
          }
        }
        @error
      end

      def headers
        controller.request.filtered_env.reduce({}) do |hash, (name, value)|
          if name.start_with?("HTTP_") && name != "HTTP_COOKIE"
            hash[name.delete_prefix("HTTP_").split("_").each(&:capitalize!).join("-")] = value
          end
          hash
        end
      end

      def as_json(options = nil)
        super(options).merge(path: @path)
      end
    end
  end
end
