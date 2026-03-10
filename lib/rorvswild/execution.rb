# frozen_string_literal: true

module RorVsWild
  class Execution
    attr_reader :parameters, :sections, :section_stack, :error_context, :runtime, :root_section, :queue_section

    attr_accessor :error, :name

    def initialize(name, parameters)
      @root_section = Section::Root.new

      @name = name
      @parameters = parameters
      @runtime = nil
      @error = nil
      @error_context = nil

      @environment = Host.to_h
      @section_stack = [@root_section]
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
      @queue_section = Section::Queue.new(queue_time_ms)
      add_section(@queue_section)
      @queue_section
    end

    def stop
      Section.stop # root section
      if @root_section.gc_time_ms > 0
        add_section(Section::GarbageCollection.new(@root_section.gc_time_ms, @root_section.gc_calls))
      end
      @runtime = @root_section.total_ms + @root_section.gc_time_ms
      @runtime += @queue_section.total_ms if @queue_section
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
