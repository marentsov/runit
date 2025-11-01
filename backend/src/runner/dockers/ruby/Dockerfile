FROM ruby:3.2

WORKDIR /app

COPY backend/src/runner/dockers/ruby/server.rb /app/server.rb

EXPOSE 5005

CMD ["ruby", "server.rb"]