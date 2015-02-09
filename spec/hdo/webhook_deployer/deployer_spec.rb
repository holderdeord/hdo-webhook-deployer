require 'spec_helper'

module Hdo
  module WebhookDeployer
    describe Deployer do
      let(:config) {
        {
          'directory' => Dir.pwd,
          'logfile'   => Pathname.new('/tmp/test.log')
        }
      }

      let(:mock_process) {
        double(io: double.as_null_object, exit_code: 0).as_null_object
      }

      before {
        File.should_receive(:open).with(config['logfile'], 'a').and_return(double.as_null_object)
      }

      it 'replaces {sha} with the revision sha' do
        config['command'] = ["foo", "bar", "revision=%{sha}"]

        ChildProcess.should_receive(:build).with("foo", "bar", "revision=5e7cac").and_return(mock_process)

        deployer = Deployer.new("name/repo", config, '5e7cac')
        deployer.deploy
      end
    end
  end
end
