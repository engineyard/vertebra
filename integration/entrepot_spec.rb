# Copyright 2008, Engine Yard, Inc.
#
# This file is part of Vertebra.
#
# Vertebra is free software: you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Vertebra is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Vertebra.  If not, see <http://www.gnu.org/licenses/>.

require File.join(File.dirname(__FILE__), 'spec_helper')
require 'vertebra/client_api'

include Vertebra

describe 'Entrepot' do
  include Vertebra::Utils

  before(:all) do
    throw "ejabberd server must be running" unless EJABBERD.is_running?

    if HERAULT.is_running?
      puts "Detected running herault, using it."
    else
      HERAULT.start
    end

    if ENTREPOT.is_running?
      puts "Detected running entrepot, using it."
    else
      ENTREPOT.start
    end

    run_agent('client')

    @client = DRbObject.new(nil, "druby://localhost:#{CLIENT[:drb_port]}")
    @api = Vertebra::ClientAPI.new(@client)
  end

  before(:each) do
    @client.clear_queues
  end

  after(:all) do
    stop_agent('client')
    ENTREPOT.stop if ENTREPOT.started?
    HERAULT.stop if HERAULT.started?
  end

  VALUE1 = {'key' => {'cluster' => Utils.resource('/cluster/42')},
            'value' => {'foo' => 'bar'}}
  VALUE2 = {'key' => {'cluster' => Utils.resource('/cluster/42'),
                      'slice' => Utils.resource('/slice/15')},
            'value' => {'baz' => 'quux'}}

  it 'should store a value directly' do
    result = @api.request('/entrepot/store', :single, VALUE1)
    result.should == VALUE1
  end

 it 'should fetch values' do
    pending 'This one hangs'
#    @api.request('/entrepot/store', :single, VALUE1)
#    @api.request('/entrepot/store', :single, VALUE2)
#    result = @api.request('/entrepot/fetch', :single, 'key' => {'cluster' => resource('/cluster/42')})
#    result.should == [VALUE1, VALUE2]
 end

 it 'should delete values' do
    pending 'write me'
 end
end
