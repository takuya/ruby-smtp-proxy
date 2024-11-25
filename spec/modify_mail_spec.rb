
RSpec.describe 'FAXの添付ファイルの処理をテスト' do


  it "can modify mail (multipage)" do
    allow(MagickUtils).to receive(:deskew_image)
    multipart_tiff_mail_str = File.read(File.realpath File.join(File.dirname(__FILE__), '/./sample/tiff-multipage.eml'))
    original_mail = Mail.read_from_string multipart_tiff_mail_str
    ret = FaxGmailProxy.modify_mail(original_mail)
    expect(ret.attachments.size).to be 3
    expect(MagickUtils).to have_received(:deskew_image).exactly(3).time
  end
  it "can modify mail (single)" do
    allow(MagickUtils).to receive(:deskew_image)
    multipart_tiff_mail_str = File.read(File.realpath File.join(File.dirname(__FILE__), '/./sample/tiff-singlepage.eml'))
    original_mail = Mail.read_from_string multipart_tiff_mail_str
    ret = FaxGmailProxy.modify_mail(original_mail)
    expect(ret.attachments.size).to be 1
    expect(MagickUtils).to have_received(:deskew_image).exactly(1).time
  end

end