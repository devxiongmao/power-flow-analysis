FROM ruby:3.2.2

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Expose the port Sinatra runs on
EXPOSE 4567

CMD ["ruby", "app.rb"]