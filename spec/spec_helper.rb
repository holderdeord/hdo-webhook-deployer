ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'hdo/webhook_deployer'
require 'fileutils'
require 'pry'

RSpec.configure { |c|
  c.include Rack::Test::Methods
  c.include Module.new {
    def with_env(hash, &blk)
      hash.each { |k,v| ENV[k] = v }

      begin
        yield
      ensure
        hash.each_key { |k| ENV[k] = nil }
      end
    end
  }

  c.color = true if $stdout.tty?

  c.after :suite do
    FileUtils.rm_rf Dir['spec/tmp/*.log']
  end
}
