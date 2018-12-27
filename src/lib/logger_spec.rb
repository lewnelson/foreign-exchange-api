require_relative "logger.rb"

describe ForeignExchangeAPILogger do
  describe "log" do

  end

  describe "error" do
    before(:each) do
      allow(ForeignExchangeAPILogger).to receive(:log)
    end

    it "it logs the data as an `ERROR` level" do
      expect(ForeignExchangeAPILogger).to receive(:log).with("ERROR", "data")
      ForeignExchangeAPILogger::error("data")
    end
  end

  describe "warning" do
    before(:each) do
      allow(ForeignExchangeAPILogger).to receive(:log)
    end

    it "it logs the data as a `WARNING` level" do
      expect(ForeignExchangeAPILogger).to receive(:log).with("WARNING", "data")
      ForeignExchangeAPILogger::warning("data")
    end
  end

  describe "info" do
    before(:each) do
      allow(ForeignExchangeAPILogger).to receive(:log)
    end

    it "it logs the data as an `INFO` level" do
      expect(ForeignExchangeAPILogger).to receive(:log).with("INFO", "data")
      ForeignExchangeAPILogger::info("data")
    end
  end

  describe "timing" do
    before(:each) do
      allow(ForeignExchangeAPILogger).to receive(:log)
    end

    it "it logs the data as a `TIMING` level and the timing" do
      start = Time.now
      finish = start + 1
      allow(Time).to receive(:now).and_return(finish)
      expect(ForeignExchangeAPILogger).to receive(:log).with("TIMING", {
        "data" => "data",
        "time_elapsed" => 1000
      })
      ForeignExchangeAPILogger::timing(start, "data")
    end
  end
end
