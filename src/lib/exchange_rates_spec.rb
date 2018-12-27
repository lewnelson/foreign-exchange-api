require_relative "exchange_rates"

describe ExchangeRates do
  describe "get_latest_rate_date" do
    before(:each) do
      @cache_transport = instance_double(Cache::Transport)
      allow(Cache).to receive(:get_transport).and_return(@cache_transport)
    end

    describe "when cached" do
      before(:each) do
        allow(@cache_transport).to receive(:get).with("ExchangeRates::get_latest_rate_date").and_return("2018-11-10")
      end

      it "retrieves the cached value" do
        expect(ExchangeRates::get_latest_rate_date).to eq(Date.strptime("2018-11-10", "%Y-%m-%d"))
      end
    end

    describe "when not cached" do
      before(:each) do
        allow(@cache_transport).to receive(:get).and_return(nil)
        @mysql_client = instance_double(Mysql2::Client)
        allow(@mysql_client).to receive(:query).and_return([
          {
            "date_recorded" => "2018-10-01"
          }
        ])
        allow(Database).to receive(:get_client).and_return(@mysql_client)
        allow(@cache_transport).to receive(:set)
      end

      it "retrieves the values from the database" do
        expect(@mysql_client).to receive(:query).with(multiline_string(%{
          SELECT date_recorded FROM exchange_rates_against_base_currency
          ORDER BY date_recorded DESC
          LIMIT 1
        }))
        expect(ExchangeRates::get_latest_rate_date).to eq(Date.strptime("2018-10-01", "%Y-%m-%d"))
      end

      it "sets the cache value with the value from the database" do
        expect(@cache_transport).to receive(:set).with(
          "ExchangeRates::get_latest_rate_date",
          "2018-10-01",
          60 * 5
        )
        ExchangeRates::get_latest_rate_date
      end
    end
  end

  describe "get_earliest_rate_date" do
    before(:each) do
      @cache_transport = instance_double(Cache::Transport)
      allow(Cache).to receive(:get_transport).and_return(@cache_transport)
    end

    describe "when cached" do
      before(:each) do
        allow(@cache_transport).to receive(:get).with("ExchangeRates::get_earliest_rate_date").and_return("2018-11-01")
      end

      it "retrieves the cached value" do
        expect(ExchangeRates::get_earliest_rate_date).to eq(Date.strptime("2018-11-01", "%Y-%m-%d"))
      end
    end

    describe "when not cached" do
      before(:each) do
        allow(@cache_transport).to receive(:get).and_return(nil)
        @mysql_client = instance_double(Mysql2::Client)
        allow(@mysql_client).to receive(:query).and_return([
          {
            "date_recorded" => "2018-09-01"
          }
        ])
        allow(Database).to receive(:get_client).and_return(@mysql_client)
        allow(@cache_transport).to receive(:set)
      end

      it "retrieves the values from the database" do
        expect(@mysql_client).to receive(:query).with(multiline_string(%{
          SELECT date_recorded FROM exchange_rates_against_base_currency
          ORDER BY date_recorded ASC
          LIMIT 1
        }))
        expect(ExchangeRates::get_earliest_rate_date).to eq(Date.strptime("2018-09-01", "%Y-%m-%d"))
      end

      it "sets the cache value with the value from the database" do
        expect(@cache_transport).to receive(:set).with(
          "ExchangeRates::get_earliest_rate_date",
          "2018-09-01",
          60 * 5
        )
        ExchangeRates::get_earliest_rate_date
      end
    end
  end

  describe "check_currency_exists" do
    before(:each) do
      @currency_code = "ABC"
      @date = Date.strptime("2018-10-10", "%Y-%m-%d")
    end

    describe "when the currency exists" do
      before(:each) do
        allow(Currencies).to receive(:currency_exists?).and_return(true)
      end

      it "does nothing" do
        expect(Currencies).to receive(:currency_exists?).with(@currency_code, @date)
        expect(ExchangeRates.check_currency_exists(@currency_code, @date)).to eq(nil)
      end
    end

    describe "when the currency does not exist" do
      before(:each) do
        allow(Currencies).to receive(:currency_exists?).and_return(false)
      end

      it "raises an ExchangeRatesInputError exception" do
        begin
          expect(Currencies).to receive(:currency_exists?).with(@currency_code, @date)
          ExchangeRates.check_currency_exists(@currency_code, @date)
          expect(true).to eq(false)
        rescue ExchangeRates::ExchangeRatesInputError => e
          expect(e.message).to eq("Currency code '#{@currency_code}' does not exist for date '#{@date}'")
        end
      end
    end
  end

  describe "check_date_is_in_range" do
    before(:each) do
      allow(ExchangeRates).to receive(:get_earliest_rate_date).and_return(Date.strptime("2018-09-10", "%Y-%m-%d"))
      allow(ExchangeRates).to receive(:get_latest_rate_date).and_return(Date.strptime("2018-09-20", "%Y-%m-%d"))
    end

    describe "when date is in range" do
      it "does nothing" do
        expect(ExchangeRates).to receive(:get_earliest_rate_date)
        expect(ExchangeRates).to receive(:get_latest_rate_date)
        expect(ExchangeRates.check_date_is_in_range(Date.strptime("2018-09-20", "%Y-%m-%d"))).to eq(nil)
      end
    end

    describe "when date preceeds earliest available date" do
      it "raises an ExchangeRatesInputError exception" do
        begin
          expect(ExchangeRates.check_date_is_in_range(Date.strptime("2018-01-20", "%Y-%m-%d"))).to eq(nil)
          expect(true).to be(false)
        rescue ExchangeRates::ExchangeRatesInputError => e
          expect(e.message).to eq("Date '2018-01-20' preceeds earliest available date - '2018-09-10'")
        end
      end
    end

    describe "when date is greater than latest available date" do
      it "raises an ExchangeRatesInputError exception" do
        begin
          expect(ExchangeRates.check_date_is_in_range(Date.strptime("2019-10-20", "%Y-%m-%d"))).to eq(nil)
          expect(true).to be(false)
        rescue ExchangeRates::ExchangeRatesInputError => e
          expect(e.message).to eq("Date '2019-10-20' cannot exceed latest available date - '2018-09-20'")
        end
      end
    end
  end

  describe "get_currency_rate" do
    before(:each) do
      @currency_code = "ABC"
      @date = Date.strptime("2018-10-10", "%Y-%m-%d")
      @cache_transport = instance_double(Cache::Transport)
      allow(Cache).to receive(:get_transport).and_return(@cache_transport)
    end

    describe "when cached" do
      before(:each) do
        allow(@cache_transport).to receive(:get).with("ExchangeRates::get_currency_rate__#{@currency_code}_#{@date}").and_return("1.183737")
      end

      it "retrieves the cached value" do
        expect(ExchangeRates.get_currency_rate(@currency_code, @date)).to eq(1.183737)
      end
    end

    describe "when not cached" do
      before(:each) do
        allow(@cache_transport).to receive(:get).and_return(nil)
        @mysql_client = instance_double(Mysql2::Client)
        @statement = instance_double(Mysql2::Statement)
        allow(@mysql_client).to receive(:prepare).and_return(@statement)
        allow(@statement).to receive(:execute).and_return([
          { "rate" => 1.28282 }
        ])
        allow(Database).to receive(:get_client).and_return(@mysql_client)
        allow(@cache_transport).to receive(:set)
      end

      it "retrieves the values from the database" do
        expect(@mysql_client).to receive(:prepare).with(multiline_string(%{
          SELECT e_rates.rate AS rate
          FROM exchange_rates_against_base_currency AS e_rates
          LEFT JOIN currencies ON e_rates.currency_id=currencies.id
          WHERE e_rates.date_recorded=? AND currencies.currency_code=?
          LIMIT 1
        }))
        expect(@statement).to receive(:execute).with(@date, @currency_code)
        expect(ExchangeRates.get_currency_rate(@currency_code, @date)).to eq(1.28282)
      end

      it "sets the cache value with the value from the database" do
        expect(@cache_transport).to receive(:set).with(
          "ExchangeRates::get_currency_rate__#{@currency_code}_#{@date}",
          1.28282,
          60 * 5
        )
        ExchangeRates.get_currency_rate(@currency_code, @date)
      end

      describe "when rate from database is nil" do
        before(:each) do
          allow(@statement).to receive(:execute).and_return([
            { "rate" => nil }
          ])
        end

        it "raises a StandardError" do
          begin
            expect(@cache_transport).not_to receive(:set)
            ExchangeRates.get_currency_rate(@currency_code, @date)
            expect(true).to eq(false)
          rescue StandardError => e
            expect(e.message).to eq("Unable to find rate for currency_code='#{@currency_code}' on date='#{@date}'")
          end
        end
      end
    end
  end

  describe "at" do
    before(:each) do
      @date = Date.today
      @from_currency_code = "ABC"
      @to_currency_code = "DEF"
      allow(ExchangeRates).to receive(:check_date_is_in_range)
      allow(ExchangeRates).to receive(:check_currency_exists)
      allow(ExchangeRates).to receive(:get_currency_rate).and_return(100, 200)
    end

    it "checks the date is in range" do
      expect(ExchangeRates).to receive(:check_date_is_in_range).with(@date)
      ExchangeRates.at(@date, @from_currency_code, @to_currency_code)
    end

    it "checks the from currency code exists" do
      expect(ExchangeRates).to receive(:check_currency_exists).with(@from_currency_code, @date)
      ExchangeRates.at(@date, @from_currency_code, @to_currency_code)
    end

    it "checks the from to code exists" do
      expect(ExchangeRates).to receive(:check_currency_exists).with(@to_currency_code, @date)
      ExchangeRates.at(@date, @from_currency_code, @to_currency_code)
    end

    it "returns the resulting rate" do
      expect(ExchangeRates).to receive(:get_currency_rate).with(@from_currency_code, @date)
      expect(ExchangeRates).to receive(:get_currency_rate).with(@to_currency_code, @date)
      expect(ExchangeRates.at(@date, @from_currency_code, @to_currency_code)).to eq(0.5)
    end
  end

  describe "exchange_currency" do
    before(:each) do
      @date = Date.today
      @from_currency_code = "ABC"
      @to_currency_code="DEF"
      @amount = 100
      expect(ExchangeRates).to receive(:at).and_return(1.3837277)
    end

    it "uses the rate from `at` to multiply the amount" do
      expect(ExchangeRates.exchange_currency(@date, @from_currency_code, @to_currency_code, @amount)).to eq(138.37)
    end
  end
end
