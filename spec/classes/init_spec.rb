require 'spec_helper'
describe 'net-interface' do

  context 'with defaults for all parameters' do
    it { should contain_class('net-interface') }
  end
end
