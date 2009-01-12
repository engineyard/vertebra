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

describe 'Cavalcade' do

  before(:all) do
    throw "ejabberd server must be running" unless EJABBERD.is_running?

    if HERAULT.is_running?
      puts "Detected running herault, using it."
    else
      HERAULT.start
    end

    if CAVALCADE.is_running?
      puts "Detected running cavalcade, using it."
    else
      CAVALCADE.start
    end

    run_agent('client')
    run_agent('slice_agent')

    @client = DRbObject.new(nil, "druby://localhost:#{CLIENT[:drb_port]}")
    @api = Vertebra::ClientAPI.new(@client)
    @slice_agent = DRbObject.new(nil, "druby://localhost:#{SLICE_AGENT[:drb_port]}")
  end

  before(:each) do
    @client.clear_queues
    @slice_agent.clear_queues
  end

  after(:all) do
    stop_agent('client')
    stop_agent('slice_agent')
    CAVALCADE.stop if CAVALCADE.started?
    HERAULT.stop if HERAULT.started?
  end

  CAVALCADE_JID = 'cavalcade@localhost/cavalcade'

  it 'Should discover cavalcade' do
    result = @api.discover '/workflow'
    result['jids'].first.should == CAVALCADE_JID
  end

  it 'Should save a workflow' do
    workflow = '<workflow name="list_gems" start="find_slices"></workflow>'
    result = @api.op('/workflow/store', CAVALCADE_JID, :workflow => workflow)
    result.should == {'result' => "ok"}
  end

  it 'Should execute a workflow' do
    workflow =<<-EOT
      <workflow name="list_gems" start="find_slices">
        <state name="find_slices">
          <op type="/security/discover">
            <string name="target">herault@localhost/herault</string>
            <res name="op">/gem</res>
            <output>
	          <all name="agents" />
            </output>
          </op>
          <transition type="default">get_gems</transition>
        </state>
        <state name="get_gems">
          <op type="/gem/list">
            <import name="agents" type="target" />
            <output>
	          <all name="results" />
            </output>
          </op>
          <transition type="end" />
        </state>
      </workflow>
    EOT
    @api.op('/workflow/store', CAVALCADE_JID, :workflow => workflow)

    expected_result = @api.request('/gem/list', res('/gem')).first
    #result = @api.op('/workflow/execute', CAVALCADE_JID, :workflow => 'list_gems')
    #response = result['workflow_results'].detect do |item|
    #  Hash === item and item.key? 'response'
    #end
    #response.should == expected_result
  end
end
