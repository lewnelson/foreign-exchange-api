require_relative "config.rb"

describe ForeignExchangeAPIConfig do
  describe "get" do
    after(:each) do
      ENV["MY_ENV_VAR"] = ""
    end

    it "gets the `key` value from ENV" do
      ENV["MY_ENV_VAR"] = "value"
      expect(ForeignExchangeAPIConfig::get("MY_ENV_VAR", "Fallback")).to eq("value")
    end

    it "returns the fallback value when the ENV `key` is not available" do
      expect(ForeignExchangeAPIConfig::get("MY_ENV_VAR", "Fallback")).to eq("Fallback")
    end
  end

  describe "is_production?" do
    it "returns true when config for `IS_PRODUCTION` is 'true'" do
      allow(ForeignExchangeAPIConfig).to receive(:get).with("IS_PRODUCTION").and_return("true")
      expect(ForeignExchangeAPIConfig::is_production?).to eq(true)
    end

    it "returns false when config for `IS_PRODUCTION` is not `true`" do
      allow(ForeignExchangeAPIConfig).to receive(:get).with("IS_PRODUCTION").and_return("")
      expect(ForeignExchangeAPIConfig::is_production?).to eq(false)
    end
  end
end
