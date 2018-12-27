require_relative "cache.rb"

describe Cache do
  before(:each) do
    allow(ForeignExchangeAPIConfig).to receive(:get).with("REDIS_PATH").and_return("/redis-path")
    allow(ForeignExchangeAPIConfig).to receive(:get).with("REDIS_URL").and_return("/redis-url")
  end

  describe "is_redis_available?" do
    it "returns false when REDIS_PATH length is 0 and REDIS_URL length is 0" do
      allow(ForeignExchangeAPIConfig).to receive(:get).with("REDIS_PATH").and_return("")
      allow(ForeignExchangeAPIConfig).to receive(:get).with("REDIS_URL").and_return("")
      expect(Cache::is_redis_available?).to eq(false)
    end

    it "returns true when REDIS_PATH is available" do
      allow(ForeignExchangeAPIConfig).to receive(:get).with("REDIS_URL").and_return("")
      expect(Cache::is_redis_available?).to eq(true)
    end

    it "returns true when REDIS_URL is available" do
      allow(ForeignExchangeAPIConfig).to receive(:get).with("REDIS_PATH").and_return("")
      expect(Cache::is_redis_available?).to eq(true)
    end
  end

  describe "Transport" do
    before(:each) do
      @instance = Cache::Transport.new
    end

    it "returns nil on get" do
      expect(@instance.get("key")).to eq(nil)
    end

    it "does nothing on set" do
      expect(@instance.set("key", "value")).to eq(nil)
    end
  end

  describe "RedisTransport" do
    before(:each) do
      @redis = instance_double(Redis)
      allow(Redis).to receive(:new).and_return(@redis)
    end

    describe "when instantiating Redis raises a StandardError" do
      before(:each) do
        @error = StandardError.new("redis error")
        allow(ForeignExchangeAPILogger).to receive(:error)
        allow(Redis).to receive(:new).and_raise(@error)
      end

      it "logs an error for connecting to redis" do
        expect(ForeignExchangeAPILogger).to receive(:error).with({
          "message" => "Error connecting to redis",
          "redis_url" => "/redis-url",
          "redis_path" => "/redis-path",
          "error" => @error
        })
        Cache::RedisTransport.new
      end
    end

    describe "when the REDIS_PATH is defined" do
      before(:each) do
        allow(ForeignExchangeAPIConfig).to receive(:get).with("REDIS_URL").and_return("")
      end

      it "instantiates redis with the REDIS_PATH" do
        expect(Redis).to receive(:new).with(path: "/redis-path")
        Cache::RedisTransport.new
      end
    end

    describe "when the REDIS_URL is defined" do
      before(:each) do
        allow(ForeignExchangeAPIConfig).to receive(:get).with("REDIS_PATH").and_return("")
      end

      it "instantiates redis with the REDIS_URL" do
        expect(Redis).to receive(:new).with(url: "/redis-url")
        Cache::RedisTransport.new
      end
    end

    describe "get" do
      before(:each) do
        @instance = Cache::RedisTransport.new
        allow(@redis).to receive(:get).with("key").and_return("value")
      end

      it "returns the value from Redis.get(key)" do
        expect(@instance.get("key")).to eq("value")
      end

      describe "when redis.get raises a StandardError" do
        before(:each) do
          @error = StandardError.new("redis warning")
          allow(ForeignExchangeAPILogger).to receive(:warning)
          allow(@redis).to receive(:get).and_raise(@error)
        end

        it "logs a warning" do
          expect(ForeignExchangeAPILogger).to receive(:warning).with({
            "message" => "Unable to retrieve redis value",
            "params" => {
              "key" => "key"
            },
            "error" => @error
          })
          @instance.get("key")
        end
      end
    end

    describe "set" do
      before(:each) do
        @instance = Cache::RedisTransport.new
        allow(@redis).to receive(:set)
        allow(@redis).to receive(:expire)
      end

      describe "when ttl is set to 0" do
        it "calls Redis.set with the key and value" do
          expect(@redis).to receive(:set).with("key", "value")
          @instance.set("key", "value")
        end

        it "does not call Redis.expire" do
          expect(@redis).not_to receive(:expire)
          @instance.set("key", "value")
        end
      end

      describe "when ttl is greater than 0" do
        it "calls Redis.set with the key and value" do
          expect(@redis).to receive(:set).with("key", "value")
          @instance.set("key", "value", 100)
        end

        it "calls Redis.expire with the key and ttl" do
          expect(@redis).to receive(:expire).with("key", 100)
          @instance.set("key", "value", 100)
        end
      end

      describe "when redis.set raises a StandardError" do
        before(:each) do
          @error = StandardError.new("redis warning")
          allow(ForeignExchangeAPILogger).to receive(:warning)
          allow(@redis).to receive(:set).and_raise(@error)
        end

        it "logs a warning" do
          expect(ForeignExchangeAPILogger).to receive(:warning).with({
            "message" => "Unable to set redis value",
            "params" => {
              "key" => "key",
              "value" => "value",
              "ttl" => 0
            },
            "error" => @error
          })
          @instance.set("key", "value")
        end
      end
    end
  end
end
