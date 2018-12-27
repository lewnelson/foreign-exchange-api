require "redis"
require_relative "logger.rb"
require_relative "config.rb"

module Cache
  def self.get_redis_path
    return ForeignExchangeAPIConfig::get("REDIS_PATH")
  end

  def self.get_redis_url
    return ForeignExchangeAPIConfig::get("REDIS_URL")
  end

  def self.is_redis_available?
    return Cache::get_redis_path.length > 0 || Cache::get_redis_url.length > 0
  end

  class Transport
    def get (key)
      return nil
    end

    def set (key, value, ttl = 0)
    end
  end

  class RedisTransport
    def initialize
      redis_path = Cache::get_redis_path
      redis_url = Cache::get_redis_url
      begin
        if redis_path.length > 0
          @redis = Redis.new(path: redis_path)
        else
          @redis = Redis.new(url: redis_url)
        end
      rescue StandardError => e
        ForeignExchangeAPILogger::error({
          "message" => "Error connecting to redis",
          "redis_url" => redis_url,
          "redis_path" => redis_path,
          "error" => e
        })
      end
    end

    def get (key)
      begin
        return @redis.get(key)
      rescue StandardError => e
        ForeignExchangeAPILogger::warning({
          "message" => "Unable to retrieve redis value",
          "params" => {
            "key" => key
          },
          "error" => e
        })
      end
    end

    def set (key, value, ttl = 0)
      begin
        @redis.set(key, value)
        if ttl > 0
          @redis.expire(key, ttl)
        end
      rescue StandardError => e
        ForeignExchangeAPILogger::warning({
          "message" => "Unable to set redis value",
          "params" => {
            "key" => key,
            "value" => value,
            "ttl" => ttl
          },
          "error" => e
        })
      end
    end
  end

  def self.get_transport
    if @transport
      return @transport
    end

    if !self.is_redis_available?
      @transport = RedisTransport.new()
    else
      @transport = Transport.new()
    end
  end
end
