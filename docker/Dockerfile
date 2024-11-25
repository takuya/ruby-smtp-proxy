FROM ruby:3.1-alpine

RUN mkdir -p  /smtp_proxy/src
COPY ../../ /smtp_proxy/

WORKDIR /smtp_proxy/
RUN apk add build-base ruby-dev imagemagick
RUN bundle install
RUN mkdir /var/log/smtp_proxy_server
EXPOSE 2525

ENTRYPOINT [ "/smtp_proxy/etc/init.d/smtp_proxy.rb","run" ]

