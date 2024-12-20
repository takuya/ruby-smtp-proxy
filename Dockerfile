FROM ruby:3.1-alpine

RUN mkdir -p  /ruby-smtp-proxy
COPY .. /ruby-smtp-proxy/

WORKDIR /ruby-smtp-proxy/
RUN apk add build-base git ruby-dev imagemagick imagemagick-jpeg imagemagick-tiff imagemagick-pdf
RUN bundle install
RUN mkdir /var/log/smtp_proxy_server
EXPOSE 2525

ENTRYPOINT [ "/ruby-smtp-proxy/etc/init.d/smtp_proxy","run" ]

