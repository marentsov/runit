FROM ruby:3.2-slim
WORKDIR /app
RUN gem install sinatra
COPY backend/src/runner/dockers/ruby/server.rb /app/server.rb
EXPOSE 5005
CMD ["ruby", "server.rb"]