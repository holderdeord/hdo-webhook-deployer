require 'sinatra/base'
require 'celluloid'
require 'childprocess'
require 'json'
require 'pathname'
require 'digest'

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

      def project_for(name)
        # dup ?
        projects[name]
      end

      def projects
        config.fetch('projects')
      end
    end

  end
end

require 'hdo/webhook_deployer/build'
require 'hdo/webhook_deployer/deployer'
require 'hdo/webhook_deployer/app'