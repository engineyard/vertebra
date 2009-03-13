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

$TESTING = true
$:.push File.join(File.join(File.dirname(__FILE__), '../vertebra-rb'), 'lib')

require 'rubygems'
require 'pp'
require 'drb'
require 'yaml'
require 'rr'
require 'spec'
require 'vertebra/extensions'

def yaml(file)
  YAML.load(File.read(File.dirname(__FILE__)+"/config/#{file}.yml")).symbolize_keys
end

def process_exists?(name)
  result = `ps auwx | grep '#{name}' | grep -v grep | grep -v tail`
  result = result.split.select {|x| x =~ /\s#{name}\s/}
  !result.empty?
end

def debug_options
  val = ENV['DEBUG'] ? '-d' : ''
  val << ' -J' if ENV['JABBER_DEBUG']
end

def vagent
  "#{File.dirname(__FILE__)}/../vertebra-rb/bin/vagent"
end

def run_agent(name)
  if !process_exists?(name)
    puts("#{vagent} start -c #{File.dirname(__FILE__)}/config/#{name}.yml -b")
    system("#{vagent} start -c #{File.dirname(__FILE__)}/config/#{name}.yml -b")
    sleep 1
  end
end

def stop_agent(name)
  # Should add a working check for whether the process exists back into here.
  system("#{vagent} stop -c #{File.dirname(__FILE__)}/config/#{name}.yml")
end

def warm_up(retries = 5, wait_factor = 1, *args)
  wait_factor = 1 if wait_factor == 0
  tries = 0
  sleep_duration = 0
  begin
    tries += 1
    sleep sleep_duration
    sleep_duration += (tries * wait_factor)
    result = yield(*args)
    raise "trigger retry" unless result or tries >= retries
  rescue Exception
    retry unless tries >= retries
  end
  result
end

CLIENT      = yaml('client') unless self.class.const_defined?(:CLIENT)
SLICE_AGENT = yaml('slice_agent') unless self.class.const_defined?(:SLICE_AGENT)
NODE_AGENT  = yaml('node_agent') unless self.class.const_defined?(:NODE_AGENT)

Spec::Runner.configure do |config|
  config.mock_with :rr
  # or if that doesn't work due to a version incompatibility
  # config.mock_with RR::Adapters::Rspec
end

# Create new processes in a platform independent way, and capture the
# PID of the created process so that it can be properly cleaned up, later.

class ErlangAgent
  attr_reader :app, :config, :erlang_app, :node, :script

  def initialize(name, opts = {})
    mydir = File.dirname(__FILE__)
    lib = opts[:lib] || File.expand_path("#{mydir}/..")
    @app = opts[:app] || name.to_s
    @erlang_app = opts[:erlang_app] || name.to_s
    @node = opts[:node] || "#{name}@localhost"
    @script = File.expand_path("#{lib}/vertebra-erl/bin/vertebractl")
    @config = File.expand_path("#{mydir}/config/vertebractl.conf")
    raise "#{@script} does not exist" unless File.exist? @script
  end

  def is_running?
    ping && started(erlang_app)
  end

  def started?
    @started
  end

  def start
    method_missing(:start)
    unless waitfor(erlang_app)
      raise "Error starting #{app}."
    end
    @started = true
  end

  def stop
    method_missing(:stop)
    sleep 1 until not is_running?
    @started = false
  end

  def method_missing(name, *args)
    args = args.collect {|a| a.to_s}.join(' ')
    if FileTest.exist? config
      system("#{script} #{app} --config #{config} --node #{node} #{name} #{args} > /dev/null")
    else
      system("#{script} #{app} --node #{node} #{name} #{args} > /dev/null")
    end
  end
end

HERAULT = ErlangAgent.new('herault') unless self.class.const_defined?(:HERAULT)
ENTREPOT = ErlangAgent.new('entrepot') unless self.class.const_defined?(:ENTREPOT)
CAVALCADE = ErlangAgent.new('cavalcade') unless self.class.const_defined?(:CAVALCADE)
# This doesn't actually wrap ejabberdctl, so just use it for #is_running?
EJABBERD = ErlangAgent.new('ejabberd',
                           :app => 'vertebra',
                           :node => "ejabberd@localhost") unless self.class.const_defined?(:EJABBERD)
