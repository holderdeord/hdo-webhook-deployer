module Hdo
  module WebhookDeployer
    class App < Sinatra::Base

      set :public_folder, File.expand_path("../public", __FILE__)
      set :views,         File.expand_path("../views", __FILE__)

      configure {
        raise "no projects configured" if WebhookDeployer.projects.empty?
        raise "invalid 'logdir': #{WebhookDeployer.logdir.inspect}" unless WebhookDeployer.logdir.exist?
      }

      get '/' do
        @files = Dir[WebhookDeployer.logdir.join("**/*.log").to_s].sort_by { |e| File.mtime(e) }
        @files = @files.reverse.map { |e| e.gsub(WebhookDeployer.logdir.to_s, '') }

        erb :index
      end

      get '/*.log' do |path|
        path = WebhookDeployer.logdir.join("#{path}.log")

        if path.exist?
          content_type :text
          send_file path.to_s
        else
          halt 404
        end
      end

      post '/deploy' do
        build = Build.new(json_body)

        if build.passed?
          config = config_for(build)
          check_auth build, config

          Deployer.new(config, build.commit).async.execute
        end
      end

      helpers {
        def json_body
          JSON.parse request.body.read
        rescue JSON::ParserError
          halt 400, 'invalid json body'
        end

        def config_for(build)
          short_name      = build.short_name
          branch          = build.branch
          name_and_branch = "#{short_name}##{branch}"

          config = WebhookDeployer.project_for(name_and_branch)
          config or halt(404, "no such project: #{name_and_branch}")

          config.merge('logfile' => build.log_file)
        end

        def check_auth(build, config)
          token = config['token'] || ENV['TRAVIS_TOKEN']
          return if token.nil?

          expected = Digest::SHA256.hexdigest("#{build.short_name}#{token}")
          actual   = request.env['HTTP_AUTHORIZATION']

          halt 401 if actual != expected
        end
      }

    end
  end
end