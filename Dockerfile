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
RUN apt-get update && apt-get -y install cron
COPY Gemfile Gemfile.lock /usr/src/app/
RUN bundle install

# Bundle app source
COPY . /usr/src/app/

# Setup cronjobs
COPY crontab /etc/cron.d/cron-tasks
RUN chmod +x /etc/cron.d/cron-tasks
RUN touch /usr/src/app/logs/cron_update_exchange_rates.log
RUN crontab /etc/cron.d/cron-tasks

EXPOSE 4567

CMD ["./scripts/docker_start.sh"]
