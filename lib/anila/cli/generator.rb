require "thor"
require "json"

module Anila
  module CLI
    class Generator < Thor
      include Thor::Actions

      no_commands do
        def which(cmd)
          exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
          ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
            exts.each { |ext|
              exe = File.join(path, "#{cmd}#{ext}")
              return exe if File.executable? exe
            }
          end
          return nil
        end

        def install_dependencies(deps=[])
          if deps.include?("git") && !which("git")
            say "Can't find git. You can install it by going here: http://git-scm.com/"
            exit 1
          end

          if deps.include?("node") && !which("node")
            say "Can't find NodeJS. You can install it by going here: http://nodejs.org"
            exit 1
          end

          if deps.include?("bower") && !which("bower")
            say "Can't find Bower. You can install it by running: [sudo] npm install -g bower"
            exit 1
          end

          if deps.include?("grunt") && !which("grunt")
            say "Can't find Grunt. You can install it by running: [sudo] npm install -g grunt-cli"
            exit 1
          end

          if deps.include?("gulp") && !which("gulp")
            say "Can't find Gulp. You can install it by running: [sudo] npm install -g gulp"
            exit 1
          end

          if deps.include?("compass") && !which("compass")
            # Auto install Compass as a convenience
            run("gem install compass", capture: true, verbose: false)
            run("rbenv rehash", capture: true, verbose: false) if which("rbenv")
            unless which("compass")
              say "Can't find compass. You can install it by running: gem install compass"
              exit 1 
            end
          end
        end
      end

      desc "version", "Display CLI version"
      def version
        puts "v#{Anila::CLI::VERSION}"
      end

      desc "upgrade", "Upgrade your Anila compass project"
      def upgrade
        install_dependencies(%w{git node bower compass})
        
        if File.exists?(".bowerrc")
          begin json = JSON.parse(File.read(".bowerrc"))
          rescue JSON::ParserError
            json = {}
          end
          unless json.has_key?("directory")
            json["directory"] = "bower_components"
          end
          File.open(".bowerrc", "w") {|f| f.puts json.to_json}
        else
          create_file ".bowerrc" do
            {:directory=>"bower_components"}.to_json
          end
        end
        bower_directory = JSON.parse(File.read(".bowerrc"))["directory"]

        gsub_file "config.rb", /require [\"\']anila[\"\']/ do |match|
          match = "add_import_path \"#{bower_directory}/anila/sass\""
        end

        unless File.exists?("bower.json")
          create_file "bower.json" do
            {:name => "anila_project"}.to_json
          end
        end

        run "bower install bravocado/bower-anila --save"


        if defined?(Bundler)
          Bundler.with_clean_env do
            run("compass compile", capture: true, verbose: false)
          end
        else
          run("compass compile", capture: true, verbose: false)
        end

        say <<-EOS

Anila has been setup in your project.

To update Anila in the future, just run: anila update

        EOS
      end

      desc "new", "create new project"
      option :grunt, type: :boolean, default: false
      option :gulp, type: :boolean, default: false
      option :version, type: :string
      def new(name)
        if options[:grunt]
          install_dependencies(%w{git node bower grunt})
          repo = "https://github.com/bravocado/anila-grunt-template.git"
        elsif options[:gulp]
          install_dependencies(%w{git node gulp})
          repo = "https://github.com/bravocado/anila-gulp-template.git"
        else
          install_dependencies(%w{git node bower compass})
          repo = "https://github.com/bravocado/anila-compass-template.git"
        end

        say "Creating ./#{name}"
        empty_directory(name)
        run("git clone #{repo} #{name}", capture: true, verbose: false)
        inside(name) do
          if options[:grunt]
            say "Installing dependencies..."
            run("bower install", capture: true, verbose: false)
            File.open("build/sass/_values.scss", "w") {|f| f.puts File.read("#{destination_root}/bower_components/anila/build/sass/anila/_values.scss") }
            File.open("build/sass/_conditional.scss", "w") {|f| f.puts File.read("#{destination_root}/bower_components/anila/build/sass/anila/_conditional.scss") }
            run "npm install"
            run "grunt build"
          elsif options[:gulp]
            say "Installing dependencies..."
            run "npm install"
            File.open("build/sass/_values.scss", "w") {|f| f.puts File.read("#{destination_root}/node_modules/anila/sass/anila/_values.scss") }
            File.open("build/sass/_conditional.scss", "w") {|f| f.puts File.read("#{destination_root}/node_modules/anila/sass/anila/_conditional.scss") }
            run "gulp clean && gulp build"
          else
            say "Installing dependencies..."
            run("bower install", capture: true, verbose: false)
            if defined?(Bundler)
              Bundler.with_clean_env do
                run "compass compile"
              end
            end
          end
          run("git remote rm origin", capture: true, verbose: false)
        end

        say "./#{name} was created"
      end

      desc "update", "update an existing project"
      option :version, type: :string
      def update
        unless which("bower")
          "Please install bower. Aborting."
          exit 1
        end
        run "bower update"
      end
    end
  end
end