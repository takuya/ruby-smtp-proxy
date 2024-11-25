#!/usr/bin/env ruby
# coding: utf-8
### BEGIN INIT INFO
# Provides:          smtp_proxy
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: simple_smtp_proxy
# Description:       Simple STMP Proxy by ruby
### END INIT INFO

require 'rubygems'
require "daemons"
require 'pp'
require 'tempfile'
require 'dotenv/load'
require 'pry'

def load_env
  wd = Dir.getwd
  repos_dir=File.realpath(File.dirname(__FILE__)+"/../../")
  Dir.chdir repos_dir
  Dotenv.load('.env', '.env.sample')
  ENV['client_secret_path'] = File.realpath ENV['client_secret_path']
  ENV['token_path'] = File.realpath ENV['token_path']
  ENV['user_id'] = ENV['user_id'].strip
  raise "Empty file (#{ENV['token_path']})." unless YAML.load_file(ENV['token_path'])
  ENV['user_id'] = YAML.load_file(ENV['token_path']).keys[0] if ENV['user_id'].empty?
  Dir.chdir wd
end

require_relative '../../lib/fax-gmail-proxy'

load_env
ENV['DEBUG'] = '1'

repos_dir=File.realpath(File.dirname(__FILE__)+"/../../")
Dir.chdir repos_dir
server_args ={
  hosts: "0.0.0.0",
  ports: 2525,
  user_id: ENV['user_id'],
  token_path: ENV['token_path'],
  client_secret_path: ENV['client_secret_path'],
}

if ENV['DEBUG'] == '1'
  server = FaxGmailProxy.new(**server_args)
  server.start
  server.join
  return
end

options ={
  :app_name => 'smtp-proxy',
  :backtrace=> true,
  :monitor=>true,
  :log_dir => "/var/log/smtp_proxy_server",
  :log_output => true,
  :dir_mode => :system,

}

Daemons.run_proc("smtp_proxy_server", options ){
  begin
    server = FaxGmailProxy.new(**server_args)
    server.start
    server.join
  rescue => e
    p e
    raise e
    #retry
  end
}

