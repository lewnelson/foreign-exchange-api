# Usage docs

## Contents
1. [Getting started](#getting-started)
1. [Environment variables](#environment-variables)
1. [Database setup](#database-setup)
1. [Redis setup](#redis-setup)
1. [Process management](#process-management)
1. [Logging](#logging)
1. [Unit tests](#unit-tests)

## Getting started
Install dependencies
* [RVM](https://rvm.io/)
* [Bundler](https://bundler.io/)

```
rvm install
rvm use
bundle install
```

* [Setup the database](#database-setup)
* [Setup Redis](#redis-setup) (optional)

Start the service
```
./scripts/start.sh
```

This will start the HTTP server on port `4567` and start the process which updates the exchange rates from source into the database.

## Environment variables

Setting environment variable on Mac OS / Linux `export RACK_ENV=production`.

| Name | Type | Description | Required? | Default |
| ---- | ---- | ----------- | --------- | ------- |
| RACK_ENV | String | Set the environment, e.g. "development", "production" | No | "development" |
| REDIS_PATH | String | Path to socket for Redis connection | No | "" |
| REDIS_URL | String | URI for Redis connection | No | "" |
| DB_HOST | String | MySQL database host | No | "localhost" |
| DB_UNAME | String | MySQL database username | No | "root" |
| DB_PASS | String | MySQL database password | No | "" |
| DB_PORT | Integer | MySQL database port | No | 3306 |

## Database setup

The service requires a MySQL database in order to store the currency exchange rates.

Load schema from `database/schema.sql` into your MySQL database server. Note that the schema will drop tables before creating them so only do this when creating a new database. Ensure you set the correct environment variables to connect to your database, see [environment variables](#environment-variables).

To load values into the database run
```
ruby src/cronjobs/update_exchange_rates.rb
```
This script is intended to be run as a cronjob and is used in the docker build running every 15 minutes.

## Redis setup

This service optionally uses Redis to cache database queries. In order to make use of this simply provide either the `REDIS_PATH` or `REDIS_URL` environment variable, see [environment variables](#environment-variables).

## Logging

`./scripts/start.sh` will direct STDOUT and STDERR to a file called `logs/api_server.log`.

There are 2 scripts to manage logs:
* `scripts/archive_logs.sh` - will create an archive for each processes log for the current date and copy the contents of the live log across. If an archive already exists it will append the contents of the live log to the archive. Once it has copied the contents it will clear the live log.
* `scripts/purge_logs.sh` - will remove any old log archives, any logs older than 7 days will be removed.

## Unit tests

Each src file has a corresponding test file. These are formatted as `<filename>_spec.rb`. Unit tests make use of the [rspec](http://rspec.info/) framework and the [rack-test](https://github.com/rack-test/rack-test) framework.

To run tests run the `scripts/test.sh` script. This scripts accepts an optional pattern argument which is passed to `rspec` as the `-P` argument, allowing for testing of single files or groups of files.
