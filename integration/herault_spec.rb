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

describe 'Herault' do
  include Vertebra::Utils

  before(:all) do
    throw "ejabberd server must be running" unless EJABBERD.is_running?

    if HERAULT.is_running?
      puts "Detected running herault, using it."
    else
      HERAULT.start
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
    HERAULT.stop if HERAULT.started?
  end

  HERAULT_JID = 'herault@localhost/herault'

  it 'should not include herault in discovery results' do
    pending 'write me'
  end

  it 'should include agents that advertise, but not agents that unadvertise' do
    # NOTE: unadvertise simply means advertise with TTL 0
    pending 'write me'
  end

  it 'should include /foo/bar when asked to discover /foo' do
    pending 'write me'
  end

  it 'should expire advertisements based on their TTL' do
    pending 'write me'
  end
end
