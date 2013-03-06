require 'spec_helper'

module Hdo
  module WebhookDeployer
    describe App do
      let(:app) { App }
      let(:deployer) do
        d = mock(Deployer, :execute => nil)
        d.stub(:async => d)

        d
      end

      let(:default_build) {
        {
          'repository' => {
            'owner_name' => 'testowner',
            'name'       => 'testproject'
          },
          'status' => 0,
          'branch' => 'master',
          'commit' => '6fcee6112b3bfb9ae728827dfc7fa7275f69395d'
        }
      }

      it 'should render a list of recent deploys' do
        get '/'

        last_response.status.should eql(200), last_response.body
      end

      it 'should deploy configured projects for passed builds' do
        Deployer.stub :new => deployer
        deployer.should_receive(:execute)

        post '/travis', :payload => default_build.to_json

        last_response.status.should eql(200), last_response.body
      end

      it 'should not deploy failed builds' do
        Deployer.should_receive(:new).never

        post '/travis', :payload => default_build.merge('status' => 'failed').to_json
        last_response.status.should eql(200), last_response.body
      end

      it 'should not deploy non-matching branches' do
        Deployer.should_receive(:new).never

        post '/travis', :payload => default_build.merge('branch' => 'foo').to_json
        last_response.status.should eql(404), last_response.body
      end

      it 'should not deploy non-matching owners' do
        Deployer.should_receive(:new).never

        post '/travis', :payload => default_build.merge('repository' => {
          'owner_name' => 'otherowner',
          'name' => 'testproject'
        }).to_json

        last_response.status.should eql(404), last_response.body
      end

      it 'checks authorization of the request' do
        Deployer.should_receive(:new).once.and_return(deployer)

        headers = {'HTTP_AUTHORIZATION' => Digest::SHA256.hexdigest('testowner/testprojectfoo') }

        with_env('TRAVIS_TOKEN' => 'foo') {
          post '/travis', :payload => default_build.to_json
          last_response.status.should == 401

          post '/travis', {:payload => default_build.to_json}, headers
          last_response.status.should == 200
        }
      end
    end
  end
end