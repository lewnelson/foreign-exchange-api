require_relative "currencies.rb"

describe Currencies do
  describe "get_all" do
    before(:each) do
      @date = "2018-09-23"
      @cache_transport = instance_double(Cache::Transport)
      allow(Cache).to receive(:get_transport).and_return(@cache_transport)
    end

    describe "when cached" do
      before(:each) do
        allow(@cache_transport).to receive(:get).with("Currencies::get_all__#{@date}").and_return("[\"USD\"]")
      end

      it "retrieves the cached value" do
        expect(Currencies::get_all(@date)).to eq([ "USD" ])
      end
    end

    describe "when not cached" do
      before(:each) do
        allow(@cache_transport).to receive(:get).and_return(nil)
        @mysql_client = instance_double(Mysql2::Client)
        @statement = instance_double(Mysql2::Statement)
        allow(@mysql_client).to receive(:prepare).and_return(@statement)
        allow(@statement).to receive(:execute).and_return([
          { "currency_code" => "GBP" }
        ])
        allow(Database).to receive(:get_client).and_return(@mysql_client)
        allow(@cache_transport).to receive(:set)
      end

      it "retrieves the values from the database" do
        expect(@mysql_client).to receive(:prepare).with(multiline_string(%{
          SELECT currencies.currency_code FROM exchange_rates_against_base_currency
          RIGHT JOIN currencies ON exchange_rates_against_base_currency.currency_id=currencies.id
          WHERE exchange_rates_against_base_currency.date_recorded=?
        }))
        expect(@statement).to receive(:execute).with(@date)
        expect(Currencies::get_all(@date)).to eq([ "GBP" ])
      end

      it "sets the cached value from the database when there are currencies" do
        expect(@cache_transport).to receive(:set).with(
          "Currencies::get_all__#{@date}",
          [ "GBP" ],
          60 * 5
        )
        Currencies::get_all(@date)
      end

      it "does not set the cached value from the database when there are no currencies" do
        allow(@statement).to receive(:execute).and_return([])
        expect(@cache_transport).not_to receive(:set)
        Currencies::get_all(@date)
      end
    end
  end

  describe "currency_exists?" do
    before(:each) do
      @date = "2018-07-05"
      allow(Currencies).to receive(:get_all).with(@date).and_return([ "USD", "GBP" ])
    end

    it "returns true when the currency appears in the list of currencies from get_all" do
      expect(Currencies::currency_exists?("USD", @date)).to eq(true)
    end

    it "returns false when the currency does not appear in the list of currencies from get_all" do
      expect(Currencies::currency_exists?("JPN", @date)).to eq(false)
    end
  end
end
