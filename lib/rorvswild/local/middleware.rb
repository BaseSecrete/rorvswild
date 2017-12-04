module RorVsWild
  module Local
    class Middleware
      include ERB::Util

      attr_reader :app, :config

      def initialize(app, config)
        @app, @config = app, config
      end

      def call(env)
        status, headers, response = app.call(env)
        if headers["Content-Type"] && headers["Content-Type"].include?("text/html")
          inject_html_into(response)
          [status, headers, response]
        else
          [status, headers, response]
        end
      end

      def inject_html_into(response)
        html = response.instance_variable_get(:@response).body
        if index = html.index("</body>")
          html.insert(index, html_markup(RorVsWild.agent.queue.requests))
          response.instance_variable_get(:@response).body = html
        end
        if index = html.index("</head>")
          html.insert(index, "<style type='text/css'> #{concatenate_stylesheet}</style>")
          response.instance_variable_get(:@response).body = html
        end
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
    end
  end
end
