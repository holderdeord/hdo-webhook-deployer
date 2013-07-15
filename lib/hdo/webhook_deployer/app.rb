module Hdo
  module WebhookDeployer
    class App < Sinatra::Base

      enable :sessions

      set :public_folder, File.expand_path("../public", __FILE__)
      set :views,         File.expand_path("../views", __FILE__)
      set :org_name,      'holderdeord'
      set :github_options, {
        :client_id => WebhookDeployer.config['github_client_id'] || ENV['GITHUB_CLIENT_ID'],
        :secret    => WebhookDeployer.config['github_client_secret'] || ENV['GITHUB_CLIENT_SECRET']
      }

      register Sinatra::Auth::Github

      configure {
        raise "no projects configured" if WebhookDeployer.projects.empty?
        raise "invalid 'logdir': #{WebhookDeployer.logdir.inspect}" unless WebhookDeployer.logdir.exist?
      }

      get '/' do
        files = Dir[WebhookDeployer.logdir.join("**/*.log").to_s]
        @deploys = files.map { |path| Deploy.new(path) }.sort_by { |e| e.time }.reverse

        erb :index, layout: true
      end

      get '/output/*.log' do |path|
        assert_organization_member

        path = WebhookDeployer.logdir.join("#{path}.log")

        if path.exist?
          content_type :text
          send_file path.to_s
        else
          halt 404
        end
      end

      post '/travis' do
        build = Build.new(json)

        if build.passed?
          config = config_for(build)
          check_travis_auth build.short_name, config['token']

          Deployer.new(config, build.commit).async.execute
        end
      end

      put '/travis/bundle' do
        check_basic_auth

        path = bundle_path_for(params)
        path.dirname.mkpath

        File.open(path.to_s, 'wb') do |io|
          env['rack.input'].each do |str|
            io << str
          end
        end

        'ok'
      end

      get '/travis/bundle' do
        check_basic_auth

        path = bundle_path_for(params).to_s
        send_file path, :filename => 'bundle.tgz'
      end

      get '/travis/bundle/sha' do
        check_basic_auth

        path = "#{bundle_path_for(params)}.sha1"
        File.read(path)
      end

      put '/travis/bundle/sha' do
        check_basic_auth

        path = "#{bundle_path_for(params)}.sha1"
        File.open(path, 'w') do |io|
          env['rack.input'].each { |d| io << d }
        end
      end

      helpers {
        def json
          JSON.parse params[:payload]
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

        def bundle_path_for(params)
          halt 400 unless params[:repo_slug]
          path = WebhookDeployer.bundledir.join(params[:repo_slug]).join("bundle.tgz")

          path.dirname.mkpath

          path
        end

        def check_basic_auth
          auth = Rack::Auth::Basic::Request.new(request.env)
          expected = WebhookDeployer.config['basic_auth'].split(' ')

          unless auth.provided? && auth.basic? && auth.credentials && (auth.credentials == expected)
            warden.custom_failure!
            halt 401
          end
        end

        def check_travis_auth(build_name, token)
          token ||= ENV['TRAVIS_TOKEN']
          return if token.nil?

          expected = Digest::SHA256.hexdigest("#{build_name}#{token}")
          actual   = request.env['HTTP_AUTHORIZATION']

          if actual != expected
            puts "travis auth failed: #{request.env.inspect}"

            warden.custom_failure!
            halt 401
          end
        end

        def assert_organization_member
          github_organization_authenticate!(settings.org_name)
        end
      }

    end
  end
end