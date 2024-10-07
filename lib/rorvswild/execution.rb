module RorVsWild
  class Execution
    attr_reader :name, :parameters

    def initialize(name, parameters)
      @name = name
      @parameters = parameters
    end

    class Job < Execution
    end

    class Request < Execution
    end
  end
end
