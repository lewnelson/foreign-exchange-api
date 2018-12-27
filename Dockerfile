FROM ruby:2.5.3

# Create app directory
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Install Redis
RUN wget http://download.redis.io/redis-stable.tar.gz
RUN tar xvzf redis-stable.tar.gz
RUN cd redis-stable
WORKDIR /usr/src/app/redis-stable
RUN make install
WORKDIR /usr/src/app
RUN rm -rf redis-stable redis-stable.tar.gz
RUN nohup redis-server &>/dev/null &

ENV REDIS_URL="redis://localhost:6379/1"

# Install dependencies
COPY Gemfile Gemfile.lock /usr/src/app/
RUN bundle install

# Bundle app source
COPY . /usr/src/app/

EXPOSE 4567

CMD ["./scripts/start.sh", "&&", "god restart"]
