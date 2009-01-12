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
# TODO: Make sure that this gets looked up correctly.
require 'vertebra-gemtool/actor'

include Vertebra

def resource_list(*args)
  args.collect {|a| Vertebra::Resource.new(a)}
end

describe 'Vertebra client' do

  before(:all) do
    throw "ejabberd server must be running" unless EJABBERD.is_running?
    if HERAULT.is_running?
      puts "Detected running herault, using it."
    else
      HERAULT.start
    end

    run_agent('client')
    run_agent('node_agent')
    run_agent('slice_agent')

    @client = DRbObject.new(nil, "druby://localhost:#{CLIENT[:drb_port]}")
    @api = Vertebra::ClientAPI.new(@client)
    @slice_agent = DRbObject.new(nil, "druby://localhost:#{SLICE_AGENT[:drb_port]}")
    @node_agent = DRbObject.new(nil, "druby://localhost:#{NODE_AGENT[:drb_port]}")
    warm_up do
      @node_agent.clear_queues
    end

    @resources = ['/cluster/rd00', '/slice/0', '/gem']
  end

  before(:each) do
    @client.clear_queues
    @slice_agent.clear_queues
    @node_agent.clear_queues
  end

  after(:all) do
    stop_agent('node_agent')
    stop_agent('slice_agent')
    stop_agent('client')
    HERAULT.stop if HERAULT.started?
  end

  it 'discover agent from herault' do
    result = @api.discover '/cluster/rd00', '/slice/0'
    result['jids'].first.should == SLICE_AGENT[:jid]
  end

  it 'not discover agents for a non-existent combination of resources' do
    result = @api.discover '/cluster/rd00', '/slice/536'
    result['jids'].should == []
    result = @api.discover '/cluster/ae02', '/node/1'
    result['jids'].should == []
    result = @api.discover '/some/nonexistent/resource'
    result['jids'].should == []
  end

  it 'get a number list from a slice' do
    resources = resource_list('/cluster/rd00', '/slice/0', '/mock')
    results = @api.request('/list/numbers', *resources)
    results.should == [{"response" => [1,2,3]}]
  end

  it 'get number list from slice and node that offer /mock' do
    resources = resource_list('/cluster/rd00', '/mock')
    results = @api.request('/list/numbers', *resources)
    results.should == [{"response"=>[1, 2, 3]}, {"response"=>[1, 2, 3]}]
  end

  it 'get number list from specific slice and give a final result with integer values in the array' do
    result = @api.op('/list/numbers', SLICE_AGENT[:jid], :resource => res('/mock'))
    result.should == {'response' => [1,2,3]}
  end

  it 'get letter list from a slice' do
    resources = resource_list('/cluster/rd00', '/slice/0', '/mock')
    results = @api.request('/list/letters', *resources)
    results.should == [{"response" => ['a','b','c']}]
  end

  it 'get gem list' do
    expected = VertebraGemtool::Actor.new.list

    resources = resource_list('/cluster/rd00', '/slice/0', '/gem')
    results = @api.request('/gem/list', *resources)
    results.first['response']['result'].should == expected[:result]
  end

  it 'get a number list from a slice' do
    resources = resource_list('/cluster/rd00', '/slice/0', '/mock')
    start = Time.now
    40.times do |n|
      results = @api.request('/list/numbers', *resources)
    end
    finish = Time.now
    puts "\n40 ops took #{finish - start} seconds: #{40 / (finish - start)}/second"
  end

end
