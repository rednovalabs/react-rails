module React
  module JSX
    class Processor
      def self.call(input)
        if JSX::transform_options.respond_to?(:call)
          JSX::transform_with_proc_options(input)
        else
          JSX::transform(input[:data])
        end
      end
    end
  end
end
