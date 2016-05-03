require 'tilt'

module React
  module JSX
    # Sprockets 2-compliant processor
    class Template < Tilt::Template
      self.default_mime_type = 'application/javascript'

      def prepare
      end

      def evaluate(scope, locals, &block)
        @output ||= JSX::transform(data, {name: scope.logical_path, filename: file})
      end
    end
  end
end
