require 'takuya/gmail-forwarder'
require 'BrotherFaxMessage'

class FaxGmailProxy <Takuya::GMailForwarderServer
  def initialize(user_id: nil, password: nil, client_secret_path: nil, token_path: nil, **args)
    super
    @working =false
  end
  ## override
  def serve_client(session, io)
    @working = true
    super(session, io)
    @working = false
  end
  def stop(wait_seconds_before_close: nil, gracefully: nil)
    while processing? do
      sleep 1
    end
    super
    sleep 0.3 until stopped?
  end
  def processing?
    @working
  end

  # @return envelope_from, envelope_to, mail
  # @param original_mail [Mail::Message]
  # @param envelope_from [String]
  # @param envelope_to [Enumerable]
  def on_proxy_send_mail(envelope_from, envelope_to, original_mail)
    has_attachments = original_mail.attachments.size>0
    unless has_attachments
      return [envelope_from, envelope_to, original_mail]
    end
    ##
    modified_mail = self.class.modify_mail(original_mail)
    [envelope_from, envelope_to, modified_mail]
  end
  # @param mail [Mail::Message]
  def is_tiff_fax_mail?(mail)
    mail.attachments.any?{|a| a.content_type&& a.content_type =~ /tiff/  } ||
      mail.attachments.any?{|a|  a.content_disposition &&  a.content_disposition =~/tiff;/ }
  end
  # @param mail [Mail::Message]
  def is_image_attached_mail?(mail)
      mail.attachments.any?{|a|  a.content_disposition &&  a.content_disposition =~/image;/ }
  end



  # @return mail [Mail::Message]
  # @param original_mail [Mail::Message]
  def self.modify_mail(original_mail)
    b = BrotherFaxMessage.new(original_mail.encoded)
    mail = b.modify_mail
  end

end

# sterling-sanded-ungloved