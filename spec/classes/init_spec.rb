require 'spec_helper'
describe 'net_interface' do

  context 'with defaults for all parameters' do
    it { should contain_class('net_interface') }
  end
end
