require 'pp'

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

      post '/travis/bundle' do
        pp params
      end

      put '/travis/bundle' do
        pp params
      end

      get '/travis/bundle' do
        pp params
      end

      get '/travis/bundle/sha' do
        '8b342388b89a702e3c8530cf541f8b17a2d2ffdc'
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

        def check_travis_auth(build_name, token)
          token ||= ENV['TRAVIS_TOKEN']
          return if token.nil?

          expected = Digest::SHA256.hexdigest("#{build_name}#{token}")
          actual   = request.env['HTTP_AUTHORIZATION']

          if actual != expected
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