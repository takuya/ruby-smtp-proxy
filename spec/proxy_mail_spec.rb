require 'digest/md5'
RSpec.describe 'メールをプロキシできるかチェック' do

  ##
  mail = nil
  vault = oauth_vault
  uuid = SecureRandom.uuid
  imap = connect_imap_by_xoauth2
  host_ip = "127.0.25.25"
  host_port = rand(49151...65535)
  client_secret_path ||= ENV['client_secret_path']
  token_path ||= ENV['token_path']
  message_uid = nil
  $modified_mail

  class TestProxyClass<FaxGmailProxy
    def on_proxy_send_mail(envelope_from, envelope_to, original_mail)
      envelope_from, envelope_to, mail = super(envelope_from, envelope_to, original_mail)
      $modified_mail = mail
      [envelope_from, envelope_to, mail]
    end



  end

  server = TestProxyClass.new(
    hosts: host_ip, ports: host_port,
    user_id: vault.user, client_secret_path: client_secret_path, token_path: token_path
  )



  before(:each) do
    user_id = vault.user
    ## メール作成
    mail = lambda {
      path = 'sample/tiff-multipage.eml'
      mail_str = File.read(File.realpath File.join(File.dirname(__FILE__), path))
      mail = Mail.read_from_string mail_str
      mail.to = user_id # 自分宛てに送信
      mail.from = user_id
      mail.message_id = nil
      mail.subject = "#{mail.subject} -- #{uuid}"
      mail

    }.call

    server.start





  end

  it " メール送信テスト" do
    message_uid = nil

    search_mail = lambda { |_imap, _uuid|
      _imap.select('INBOX')
      search_criteria = ['SUBJECT', _uuid]
      message_uid = _imap.uid_search(search_criteria)[0]
      fetched_mail_str = _imap.uid_fetch(message_uid, 'RFC822')[0].attr['RFC822']
      fetched_mail = Mail.read_from_string fetched_mail_str
      #
      expect(fetched_mail.subject).to match _uuid
      expect(fetched_mail.attachments.size).to be 3
    }
    send_mail = lambda { |_smtp, _mail, user|
      res_sendmail = _smtp.sendmail(_mail.encoded, user, user)
      res_finish = _smtp.finish
      ## test response
      expect(res_sendmail.status).to eq '250'
      expect(res_sendmail.string).to match %r"completed"
      expect(res_finish.status).to eq '221'
      expect(res_finish.string).to match /Service closing transmission channel$/

    }
    check_modified = lambda{||
      expect($modified_mail.subject).to match uuid
      expect($modified_mail.attachments.size).to be 3
    }
    smtp = Net::SMTP.new(host_ip,host_port)
    smtp.start
    send_mail.call(smtp, mail, vault.user)
    sleep 0.1 while server.processing?
    check_modified.call
    search_mail.call(imap, uuid)

  end

  after(:each) do
    # ## メール削除
    delete_mail = lambda { |imap, uid|
      imap.select('INBOX')
      imap.uid_store(uid, "+FLAGS", [:Seen])
      imap.uid_store(uid, "+FLAGS", [:Deleted])
      imap.expunge
      imap.expunge
    }
    delete_mail.call(imap, message_uid)
    server.stop

  end
end