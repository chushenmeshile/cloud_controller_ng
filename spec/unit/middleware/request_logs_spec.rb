require 'spec_helper'
require 'request_logs'

module CloudFoundry
  module Middleware
    RSpec.describe RequestLogs do
      let(:middleware) { RequestLogs.new(app, logger) }
      let(:app) { double(:app, call: [200, {}, 'a body']) }
      let(:logger) { double('logger', info: nil) }
      let(:fake_request) { double('request', request_method: 'request_method', ip: '192.168.1.80', filtered_path: 'filtered_path') }
      let(:env) { {'cf.request_id' => 'ID', 'cf.user_guid' => 'user-guid'} }

      describe 'logging' do
        before do
          allow(ActionDispatch::Request).to receive(:new).and_return(fake_request)
        end

        context 'gdpr_compliant flag is false' do
          it 'returns the app response unaltered' do
            expect(middleware.call(env)).to eq([200, {}, 'a body'])
          end

          it 'logs before calling the app' do
            middleware.call(env)
            expect(logger).to have_received(:info).with(/Started.+user: user-guid.+with vcap-request-id: ID/)
          end

          it 'logs after calling the app' do
            middleware.call(env)
            expect(logger).to have_received(:info).with(/Completed.+vcap-request-id: ID/)
          end

          it 'logs have full ips' do
            middleware.call(env)
            expect(logger).to have_received(:info).with(/ip: 192.168.1.80/)
          end
        end

        context 'gdpr_compliant flag is true' do
          before do
            TestConfig.override(logging: {gdpr_compliant: 'true'})
          end

          it 'logs have anonymized ips' do
            middleware.call(env)
            expect(logger).to have_received(:info).with(/ip: 192.168.1.0/)
          end
        end
      end
    end
  end
end
