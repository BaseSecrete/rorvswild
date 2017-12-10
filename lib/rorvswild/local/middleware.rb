module RorVsWild
  module Local
    class Middleware
      include ERB::Util

      attr_reader :app, :config

      def initialize(app, config)
        @app, @config = app, config
      end

      def call(env)
        status, headers, body = app.call(env)
        if status >= 200 && status < 300 && headers["Content-Type"] && headers["Content-Type"].include?("text/html")
          if headers["Content-Encoding"]
            log_incompatible_middleware_warning
          else
            body.each { |string| inject_into(string) }
          end
        end
        [status, headers, body]
      end

      def inject_into(html)
        if index = html.index("</body>")
          html.insert(index, html_markup(RorVsWild.agent.queue.requests))
        end
        if index = html.index("</head>")
          html.insert(index, "<style type='text/css'> #{concatenate_stylesheet}</style>")
        end
        html
      end

      DIRECTORY = File.expand_path(File.dirname(__FILE__))
      JS_FILES = ["mustache.js", "barber.js", "local.js"]
      CSS_FILES = ["local.css"]

      def html_markup(data)
        html = File.read(File.join(DIRECTORY, "local.html"))
        html % {data: html_escape(data.to_json), javascript_source: concatenate_javascript}
      end

      def concatenate_javascript
        concatenate_assets(DIRECTORY, JS_FILES)
      end

      def concatenate_stylesheet
        concatenate_assets(DIRECTORY, CSS_FILES)
      end

      def concatenate_assets(directory, files)
        files.map { |file| File.read(File.join(directory, file)) }.join("\n")
      end

      def log_incompatible_middleware_warning
        RorVsWild.logger.warn("RorVsWild::Local cannot inject into your HTML response because of compression." +
          " Try to disable Rack::Deflater in development only.")
      end
    end
  end
end
