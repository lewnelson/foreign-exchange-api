require_relative "api.rb"

describe "GET /exchange-rate" do
  before(:each) do
    @browser = ForeignExchangeAPITestHelpers::get_browser
    @time_now = Time.now
    allow(Time).to receive(:now).and_return(@time_now)
    allow(ForeignExchangeAPILogger).to receive(:timing)
  end

  describe "when no parameters are provided" do
    it "returns a 400 error with validation errors for the missing parameters" do
      @browser.get "/exchange-rate"
      expect(@browser.last_response.status).to eq(400)
      expect(@browser.last_response["Content-Type"]).to eq("application/json")
      expect(@browser.last_response.body).to eq({ :errors => [
        "Invalid param `date` '', must be in the format YYYY-MM-DD",
        "Invalid param `from_currency_code` '', must conform to ISO_4217",
        "Invalid param `to_currency_code` '', must conform to ISO_4217"
      ] }.to_json)
    end
  end

  describe "when the provided parameters are invalid" do
    it "returns a 400 error with validation errors for the invalid parameters" do
      @browser.get(
        "/exchange-rate",
        :date => "09-12-2013",
        :from_currency_code => "ABCD",
        :to_currency_code => "EFGH"
      )
      expect(@browser.last_response.status).to eq(400)
      expect(@browser.last_response["Content-Type"]).to eq("application/json")
      expect(@browser.last_response.body).to eq({ :errors => [
        "Invalid param `date` '09-12-2013', must be in the format YYYY-MM-DD",
        "Invalid param `from_currency_code` 'ABCD', must conform to ISO_4217",
        "Invalid param `to_currency_code` 'EFGH', must conform to ISO_4217"
      ] }.to_json)
    end
  end

  describe "when the parameters are all valid" do
    before(:each) do
      @date = "2018-10-10"
      @from_currency_code = "USD"
      @to_currency_code = "JPN"
      allow(ExchangeRates).to receive(:at).and_return(10.123838)
    end

    describe "when it gets the exchanged rate successfully" do
      it "returns the result from ExchangeRates::at" do
        expect(ExchangeRates).to receive(:at).with(
          Date.strptime(@date, "%Y-%m-%d"),
          @from_currency_code,
          @to_currency_code
        )
        @browser.get(
          "/exchange-rate",
          :date => @date,
          :from_currency_code => @from_currency_code,
          :to_currency_code => @to_currency_code
        )
        expect(@browser.last_response.status).to eq(200)
        expect(@browser.last_response["Content-Type"]).to eq("application/json")
        expect(@browser.last_response.body).to eq({ :result => 10.123838 }.to_json)
      end

      it "logs the timing value of the request" do
        expect(ForeignExchangeAPILogger).to receive(:timing).with(@time_now, {
          "route" => "GET /exchange-rate",
          "params" => {
            :date => @date,
            :from_currency_code => @from_currency_code,
            :to_currency_code => @to_currency_code
          }
        })
        @browser.get(
          "/exchange-rate",
          :date => @date,
          :from_currency_code => @from_currency_code,
          :to_currency_code => @to_currency_code
        )
      end
    end

    describe "when ExchangeRates::at raises an ExchangeRates::ExchangeRatesInputError" do
      before(:each) do
        allow(ExchangeRates).to receive(:at).and_raise(
          ExchangeRates::ExchangeRatesInputError.new("input error")
        )
      end

      it "returns a 400 error with validation errors from the raised exception" do
        @browser.get(
          "/exchange-rate",
          :date => @date,
          :from_currency_code => @from_currency_code,
          :to_currency_code => @to_currency_code
        )
        expect(@browser.last_response.status).to eq(400)
        expect(@browser.last_response["Content-Type"]).to eq("application/json")
        expect(@browser.last_response.body).to eq({ :errors => [
          "input error"
        ] }.to_json)
      end
    end

    describe "when ExchangeRates::at raises an StandardError" do
      before(:each) do
        @error = StandardError.new("broken :(")
        allow(ExchangeRates).to receive(:at).and_raise(@error)
      end

      describe "when in production" do
        before(:each) do
          allow(ForeignExchangeAPIConfig).to receive(:is_production?).and_return(true)
        end

        it "sends a generic 500 error response" do
          @browser.get(
            "/exchange-rate",
            :date => @date,
            :from_currency_code => @from_currency_code,
            :to_currency_code => @to_currency_code
          )
          expect(@browser.last_response.status).to eq(500)
          expect(@browser.last_response["Content-Type"]).to eq("application/json")
          expect(@browser.last_response.body).to eq({ :errors => [ "internal server error" ] }.to_json)
        end
      end

      describe "when not in production" do
        before(:each) do
          allow(ForeignExchangeAPIConfig).to receive(:is_production?).and_return(false)
        end

        it "raises the error" do
          begin
            @browser.get(
              "/exchange-rate",
              :date => @date,
              :from_currency_code => @from_currency_code,
              :to_currency_code => @to_currency_code
            )
            expect(false).to eq(true)
          rescue StandardError => e
            expect(e).to be(@error)
          end
        end
      end
    end
  end
end

describe "GET /exchange-currency" do
  before(:each) do
    @browser = ForeignExchangeAPITestHelpers::get_browser
    @time_now = Time.now
    allow(Time).to receive(:now).and_return(@time_now)
    allow(ForeignExchangeAPILogger).to receive(:timing)
  end

  describe "when no parameters are provided" do
    it "returns a 400 error with validation errors for the missing parameters" do
      @browser.get "/exchange-currency"
      expect(@browser.last_response.status).to eq(400)
      expect(@browser.last_response["Content-Type"]).to eq("application/json")
      expect(@browser.last_response.body).to eq({ :errors => [
        "Invalid param `date` '', must be in the format YYYY-MM-DD",
        "Invalid param `from_currency_code` '', must conform to ISO_4217",
        "Invalid param `to_currency_code` '', must conform to ISO_4217",
        "Invalid param `amount` '', must be a number greater than 0"
      ] }.to_json)
    end
  end

  describe "when the provided parameters are invalid" do
    it "returns a 400 error with validation errors for the invalid parameters" do
      @browser.get(
        "/exchange-currency",
        :date => "09-12-2013",
        :amount => -10,
        :from_currency_code => "ABCD",
        :to_currency_code => "EFGH"
      )
      expect(@browser.last_response.status).to eq(400)
      expect(@browser.last_response["Content-Type"]).to eq("application/json")
      expect(@browser.last_response.body).to eq({ :errors => [
        "Invalid param `date` '09-12-2013', must be in the format YYYY-MM-DD",
        "Invalid param `from_currency_code` 'ABCD', must conform to ISO_4217",
        "Invalid param `to_currency_code` 'EFGH', must conform to ISO_4217",
        "Invalid param `amount` '-10', must be a number greater than 0"
      ] }.to_json)
    end
  end

  describe "when the parameters are all valid" do
    before(:each) do
      @date = "2018-10-10"
      @amount = 200
      @from_currency_code = "USD"
      @to_currency_code = "JPN"
      allow(ExchangeRates).to receive(:exchange_currency).and_return(1000)
    end

    describe "when it gets the exchanged rate successfully" do
      it "returns the result from ExchangeRates::exchange_currency" do
        expect(ExchangeRates).to receive(:exchange_currency).with(
          Date.strptime(@date, "%Y-%m-%d"),
          @from_currency_code,
          @to_currency_code,
          @amount
        )
        @browser.get(
          "/exchange-currency",
          :date => @date,
          :amount => @amount,
          :from_currency_code => @from_currency_code,
          :to_currency_code => @to_currency_code
        )
        expect(@browser.last_response.status).to eq(200)
        expect(@browser.last_response["Content-Type"]).to eq("application/json")
        expect(@browser.last_response.body).to eq({ :result => 1000 }.to_json)
      end

      it "logs the timing value of the request" do
        expect(ForeignExchangeAPILogger).to receive(:timing).with(@time_now, {
          "route" => "GET /exchange-currency",
          "params" => {
            :date => @date,
            :amount => @amount.to_s,
            :from_currency_code => @from_currency_code,
            :to_currency_code => @to_currency_code
          }
        })
        @browser.get(
          "/exchange-currency",
          :date => @date,
          :amount => @amount,
          :from_currency_code => @from_currency_code,
          :to_currency_code => @to_currency_code
        )
      end
    end

    describe "when ExchangeRates::exchange_currency raises an ExchangeRates::ExchangeRatesInputError" do
      before(:each) do
        allow(ExchangeRates).to receive(:exchange_currency).and_raise(
          ExchangeRates::ExchangeRatesInputError.new("input error")
        )
      end

      it "returns a 400 error with validation errors from the raised exception" do
        @browser.get(
          "/exchange-currency",
          :date => @date,
          :amount => @amount,
          :from_currency_code => @from_currency_code,
          :to_currency_code => @to_currency_code
        )
        expect(@browser.last_response.status).to eq(400)
        expect(@browser.last_response["Content-Type"]).to eq("application/json")
        expect(@browser.last_response.body).to eq({ :errors => [
          "input error"
        ] }.to_json)
      end
    end

    describe "when ExchangeRates::exchange_currency raises an StandardError" do
      before(:each) do
        @error = StandardError.new("broken :(")
        allow(ExchangeRates).to receive(:exchange_currency).and_raise(@error)
      end

      describe "when in production" do
        before(:each) do
          allow(ForeignExchangeAPIConfig).to receive(:is_production?).and_return(true)
        end

        it "sends a generic 500 error response" do
          @browser.get(
            "/exchange-currency",
            :date => @date,
            :amount => @amount,
            :from_currency_code => @from_currency_code,
            :to_currency_code => @to_currency_code
          )
          expect(@browser.last_response.status).to eq(500)
          expect(@browser.last_response["Content-Type"]).to eq("application/json")
          expect(@browser.last_response.body).to eq({ :error => "internal server error" }.to_json)
        end
      end

      describe "when not in production" do
        before(:each) do
          allow(ForeignExchangeAPIConfig).to receive(:is_production?).and_return(false)
        end

        it "raises the error" do
          begin
            @browser.get(
              "/exchange-currency",
              :date => @date,
              :amount => @amount,
              :from_currency_code => @from_currency_code,
              :to_currency_code => @to_currency_code
            )
            expect(false).to eq(true)
          rescue StandardError => e
            expect(e).to be(@error)
          end
        end
      end
    end
  end
end

describe "GET /supported-currencies" do
  before(:each) do
    @browser = ForeignExchangeAPITestHelpers::get_browser
    @time_now = Time.now
    allow(Time).to receive(:now).and_return(@time_now)
    allow(ForeignExchangeAPILogger).to receive(:timing)
  end

  describe "when no date is provided" do
    it "returns a 400 error with validation errors for the date" do
      @browser.get "/supported-currencies"
      expect(@browser.last_response.status).to eq(400)
      expect(@browser.last_response["Content-Type"]).to eq("application/json")
      expect(@browser.last_response.body).to eq({ :errors => [
        "Invalid param `date` '', must be in the format YYYY-MM-DD"
      ] }.to_json)
    end
  end

  describe "when the provided date is invalid" do
    it "returns a 400 error with validation errors for the date" do
      @browser.get "/supported-currencies", :date => "01-09-2011"
      expect(@browser.last_response.status).to eq(400)
      expect(@browser.last_response["Content-Type"]).to eq("application/json")
      expect(@browser.last_response.body).to eq({ :errors => [
        "Invalid param `date` '01-09-2011', must be in the format YYYY-MM-DD"
      ] }.to_json)
    end
  end

  describe "when the provided date is valid" do
    before(:each) do
      @currencies = [ "USD", "GBP" ]
      allow(Currencies).to receive(:get_all).and_return(@currencies)
    end

    it "returns the array of supported currencies" do
      @browser.get "/supported-currencies", :date => "2018-01-01"
      expect(@browser.last_response.status).to eq(200)
      expect(@browser.last_response["Content-Type"]).to eq("application/json")
      expect(@browser.last_response.body).to eq({ :result => [ "USD", "GBP" ] }.to_json)
    end

    it "logs the timing value of the request" do
      expect(ForeignExchangeAPILogger).to receive(:timing).with(@time_now, { "route" => "GET /supported-currencies" })
      @browser.get "/supported-currencies", :date => "2018-01-01"
    end
  end
end

describe "GET /earliest-supported-date" do
  before(:each) do
    @browser = ForeignExchangeAPITestHelpers::get_browser
    @time_now = Time.now
    @earliest_supported_date = Date.new(2018, 10, 10)
    allow(Time).to receive(:now).and_return(@time_now)
    allow(ForeignExchangeAPILogger).to receive(:timing)
    allow(ExchangeRates).to receive(:get_earliest_rate_date).and_return(@earliest_supported_date)
  end

  it "returns the result from ExchangeRates::get_earliest_rate_date" do
    @browser.get "/earliest-supported-date"
    expect(@browser.last_response.status).to eq(200)
    expect(@browser.last_response["Content-Type"]).to eq("application/json")
    expect(@browser.last_response.body).to eq({ :result => "2018-10-10" }.to_json)
  end

  it "logs the timing value of the request" do
    expect(ForeignExchangeAPILogger).to receive(:timing).with(@time_now, { "route" => "GET /earliest-supported-date" })
    @browser.get "/earliest-supported-date"
  end
end

describe "GET /latest-supported-date" do
  before(:each) do
    @browser = ForeignExchangeAPITestHelpers::get_browser
    @time_now = Time.now
    @latest_supported_date = Date.new(2018, 10, 10)
    allow(Time).to receive(:now).and_return(@time_now)
    allow(ForeignExchangeAPILogger).to receive(:timing)
    allow(ExchangeRates).to receive(:get_latest_rate_date).and_return(@latest_supported_date)
  end

  it "returns the result from ExchangeRates::get_latest_rate_date" do
    @browser.get "/latest-supported-date"
    expect(@browser.last_response.status).to eq(200)
    expect(@browser.last_response["Content-Type"]).to eq("application/json")
    expect(@browser.last_response.body).to eq({ :result => "2018-10-10" }.to_json)
  end

  it "logs the timing value of the request" do
    expect(ForeignExchangeAPILogger).to receive(:timing).with(@time_now, { "route" => "GET /latest-supported-date" })
    @browser.get "/latest-supported-date"
  end
end
