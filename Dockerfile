FROM ruby:2.7

WORKDIR /app

RUN gem install open-uri-cached nokogiri

COPY fetch.rb /app

RUN chmod +x fetch.rb

ENTRYPOINT ["./fetch.rb"]
