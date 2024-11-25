## FAX転送用SMTPプロキシ

- GmailForwardingする
- Forwarding前に画像を処理する
  - 画像の向きを治す
  - 画像の分割を行う。
- docker で起動する。
- テスト
  - 添付ファイル送信
    - 送信される。
    - 削除できる。
  - 通常メールを送信
    - 送信される
    - 削除できる。

## 依存モジュール

gmail 関連と、STMP-PRPOXY関連を分けて作り直した。

```ruby
# gem "rails"
gem 'takuya-xoauth2', git: 'https://github.com/takuya/ruby-google-xoauth2.git'
gem 'takuya-gmail-forwarder', git: 'https://github.com/takuya/ruby-gmail-forwarder.git'
gem 'takuya-ruby-mail-attachment-tiff', git: 'https://github.com/takuya/ruby-mail-attachment-tiff.git'
gem 'takuya-ruby-encryption', git: 'https://github.com/takuya/ruby-encryption.git'

```

## 暗号化

ファイルは暗号化している。

プライバシーなファイルは暗号化して保存する。
```ruby
bundle exec ruby spec/encrypt-privary.rb
```





