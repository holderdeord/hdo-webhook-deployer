require 'sinatra/base'
require 'sinatra/auth/github'
require 'celluloid'
require 'childprocess'
require 'json'
require 'pathname'
require 'digest'
require 'statsd'
require 'hipchat'

module Hdo
  module WebhookDeployer
    class << self
      def env
        @env ||= ENV['RACK_ENV'] || 'development'
      end

      def config
        @config ||= JSON.parse(root.join("config/#{env}.json").read)
      end

      def root
        Pathname.new File.expand_path("../../..", __FILE__)
      end

      def logdir
        @logdir ||= Pathname.new File.expand_path(config.fetch('logdir'))
      end

      def bundledir
        @bundledir ||= logdir.join('bundle')
      end

      def project_for(name)
        # dup ?
        projects[name]
      end

      def projects
        config.fetch('projects')
      end

      def hipchat
        @client ||= HipChat::Client.new(config.fetch('hipchat_token'))
      end

      def statsd
        @statsd ||= (
          host, port = config.fetch('statsd').split(":", 2)
          Statsd.new host, Integer(port)
        )
      end
    end

  end
end

require 'hdo/webhook_deployer/build'
require 'hdo/webhook_deployer/deployer'
require 'hdo/webhook_deployer/deploy'
require 'hdo/webhook_deployer/app'
