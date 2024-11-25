## spec フォルダ内部の .enc ファイルを復号化する。

require 'openssl/utils'
require 'dotenv/load'


## abc.txt.encryption -> abc.txt
def decrypt_file(enc, password, ext = '.encrypted', iter = 1000 * 1000)
  f_in = enc
  f_out = f_in.sub(ext, '')
  OpenSSLEncryption.decrypt_by_ruby(
    passphrase: password,
    file_enc: f_in,
    file_out: f_out,
    iterations: iter,
    base64: true
  )
end

def encrypt_file(src, password, ext = ".encrypted", iter = 1000 * 1000)
  f_in = src
  f_out = "#{src}#{ext}"
  OpenSSLEncryption.encrypt_by_ruby(
    passphrase: password, file_in: f_in, file_out: f_out, iterations: iter, base64: true, salted: true)
  File.unlink f_in
end

def decrypt_files_in_repository(pass,ext = '.encrypted')
  repo_home = File.realpath(File.dirname(File.dirname(__FILE__) + '/../..'))
  Dir.chdir repo_home
  files = Dir.glob("./**/*#{ext}", File::FNM_PATHNAME)
  files.reject!{|f| f =~ /vendor/ }
  binding.pry
  files.each do |f|
    decrypt_file(f, pass)
  end

end

def encrypt_files_in_repository(pass,*patterns)
  repo_home = File.realpath(File.dirname(File.dirname(__FILE__) + '/../..'))
  Dir.chdir repo_home
  files = patterns.map { |pat| Dir.glob(pat) }.flatten.sort
  files.each do |f|
    encrypt_file(f, pass)
  end
end
def load_pass
  Dotenv.load('.env', '.env.sample')
  pass = ENV['SPEC_ENC_KEY'] || ENV['openssl_enc_pass'] || ''
  raise "SPEC File decrypt pass(key) should be exists( export SPEC_ENC_KEY=your_pass )" if pass.empty?
  pass
end


## main
if __FILE__==$0
  pass = load_pass
  encrypt_files_in_repository(pass,'./spec/**/*.jpg', './spec/**/*.eml','./spec/**/*.json', './credentials/*.yaml', './credentials/*.json')
end
