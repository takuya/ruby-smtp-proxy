# frozen_string_literal: true

require 'pry'
require 'digest/md5'
require 'dotenv/load'
require 'securerandom'
require 'yaml'
require 'mail'
require 'gmail_xoauth'
require "googleauth"
require "googleauth/stores/file_token_store"
##
require_relative '../lib/fax-gmail-proxy'

## GitHub に見つからないように暗号化。
require_relative './encrypt-privary'


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.raise_errors_for_deprecations!
  Dotenv.load('.env', '.env.sample')
  ENV['client_secret_path'] = File.expand_path ENV['client_secret_path']
  ENV['token_path'] = File.expand_path ENV['token_path']
  ENV['user_id'] = ENV['user_id'].strip
  ##
  decrypt_files_in_repository(load_pass)
  #
  ENV['user_id'] = YAML.load_file(ENV['token_path']).keys[0] if ENV['user_id'].empty?
  # Thread.abort_on_exception = true




  def get_client_access_token(user,client_secret_path,token_path)
    scope       = ['https://mail.google.com/']
    authorizer  = Google::Auth::UserAuthorizer.new(
      Google::Auth::ClientId.from_file(client_secret_path),
      scope,
      Google::Auth::Stores::FileTokenStore.new(file: token_path)
    )
    credentials = authorizer.get_credentials(user)
    raise "#{user} not found in tokens.yml " unless credentials
    credentials.refresh! if credentials.expired?
    credentials.access_token
  end
  def oauth_vault()
    client_secret_path ||= ENV['client_secret_path']
    token_path ||= ENV['token_path']
    user ||= ENV['user_id']
    token = get_client_access_token(user,client_secret_path,token_path)
    Struct.new(:user,:token).new(user, token)
  end
  def connect_smtp_by_xoauth2(smtp_server = "smtp.gmail.com", tls_port = 587)
    vault = oauth_vault
    smtp  = Net::SMTP.new(smtp_server, tls_port)
    smtp.enable_starttls if tls_port == 587
    smtp.enable_tls if tls_port == 465
    smtp.start(smtp_server, vault.user, vault.token, :xoauth2)
    smtp
  end

  # @return [Net::IMAP]
  def connect_imap_by_xoauth2(imap_server = 'imap.gmail.com', tls_port=993)
    vault = oauth_vault
    imap  = Net::IMAP.new(imap_server, port: tls_port, ssl:true)
    imap.authenticate('XOAUTH2', vault.user, vault.token)
    ##
    imap
  end
end

