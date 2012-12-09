$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'hdo-webhook-deployer'

run Hdo::WebhookDeployer::App