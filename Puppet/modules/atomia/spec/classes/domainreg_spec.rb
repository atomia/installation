require 'spec_helper'

describe 'atomia::domainreg' do

        context 'create a config file with default settings' do
                it { should contain_file('domainreg.conf.puppet').with_path('/etc/domainreg.conf.puppet') }
        end


end

