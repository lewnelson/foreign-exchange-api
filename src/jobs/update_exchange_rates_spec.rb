require_relative "update_exchange_rates.rb"

describe UpdateExchangeRates do
  before(:each) do
    allow(ForeignExchangeAPILogger).to receive(:error)
    allow(ForeignExchangeAPILogger).to receive(:info)
    allow_any_instance_of(UpdateExchangeRates).to receive(:sleep)
    @instance = UpdateExchangeRates.new
  end

  describe "perform_in" do
    before(:each) do
      allow(@instance).to receive(:perform)
    end

    it "calls sleep for t seconds" do
      expect(@instance).to receive(:sleep).with(5)
      @instance.perform_in(5, 3)
    end

    it "calls perform with the attempt count" do
      expect(@instance).to receive(:perform).with(3)
      @instance.perform_in(5, 3)
    end
  end

  describe "fetch_latest_rates" do
    describe "when successful" do
      before(:each) do
        @res_instance = Net::HTTPSuccess.new(1.0, "200", "OK")
        @body = ForeignExchangeAPITestHelpers::multiline_string_to_single_line %{
          <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
            <gesmes:subject>Reference rates</gesmes:subject>
            <gesmes:Sender>
              <gesmes:name>European Central Bank</gesmes:name>
            </gesmes:Sender>
            <Cube>
              <Cube time="2018-12-20">
                <Cube currency="USD" rate="1.1451"/>
                <Cube currency="JPY" rate="127.94"/>
              </Cube>
              <Cube time="2018-12-19">
                <Cube currency="USD" rate="1.1405"/>
                <Cube currency="JPY" rate="128.11"/>
              </Cube>
            </Cube>
          </gesmes:Envelope>
        }
        allow(@res_instance).to receive(:body).and_return(@body)
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(@res_instance)
      end

      it "returns the expected results" do
        expect(@instance.fetch_latest_rates()).to eq([
          { :date_recorded => "2018-12-20", :currency_code => "USD", :rate => 1.1451 },
          { :date_recorded => "2018-12-20", :currency_code => "JPY", :rate => 127.94 },
          { :date_recorded => "2018-12-19", :currency_code => "USD", :rate => 1.1405 },
          { :date_recorded => "2018-12-19", :currency_code => "JPY", :rate => 128.11 }
        ])
      end

      it "does not retry" do
        expect(@instance).to receive(:sleep).exactly(0).times
      end
    end

    describe "when unsuccessful" do
      before(:each) do
        @res_instance = Net::HTTPError.new(1.0, "500")
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(@res_instance)
      end

      it "returns an empty result set" do
        expect(@instance.fetch_latest_rates()).to eq(Array.new)
      end

      it "attempts to fetch the latest rates 10 times 5 seconds between each call" do
        expect(@instance).to receive(:sleep).with(5)
        expect(@instance).to receive(:sleep).exactly(9).times
        @instance.fetch_latest_rates()
      end
    end
  end

  describe "add_new_rates?" do
    before(:each) do
      @mysql_client = instance_double(Mysql2::Client)
      @statement = instance_double(Mysql2::Statement)
      allow(@mysql_client).to receive(:query)
      allow(@mysql_client).to receive(:prepare).and_return(@statement)
      allow(@statement).to receive(:execute)
      allow(Database).to receive(:get_client).and_return(@mysql_client)
    end

    describe "when there are no rates to add" do
      before(:each) do
        @rates = []
      end

      it "returns true" do
        expect(@instance.add_new_rates?(@rates)).to eq(true)
      end

      it "starts an SQL transaction and commits it" do
        expect(@mysql_client).to receive(:query).with("START TRANSACTION")
        expect(@mysql_client).to receive(:query).with("COMMIT")
        @instance.add_new_rates?(@rates)
      end
    end

    describe "when there are rates to add" do
      before(:each) do
        @rates = [
          {
            :rate => 1.456,
            :date_recorded => "2018-10-10",
            :currency_code => "USD"
          }
        ]
      end

      describe "when there is an SQL error" do
        before(:each) do
          allow(@mysql_client).to receive(:prepare).and_raise(Mysql2::Error, "mysql error")
        end

        it "returns false" do
          expect(@instance.add_new_rates?(@rates)).to eq(false)
        end

        it "starts an SQL transaction and rolls it back" do
          expect(@mysql_client).to receive(:query).with("START TRANSACTION")
          expect(@mysql_client).to receive(:query).with("ROLLBACK")
          @instance.add_new_rates?(@rates)
        end

        it "logs the SQL error" do
          expect(ForeignExchangeAPILogger).to receive(:error).with({
            "message" => "Failed SQL query inserting new rates",
            "error" => instance_of(Mysql2::Error)
          })
          @instance.add_new_rates?(@rates)
        end
      end

      describe "when the rates are added successfully" do
        it "returns true" do
          expect(@instance.add_new_rates?(@rates)).to eq(true)
        end

        it "inserts the currencies into the database" do
          expect(@mysql_client).to receive(:prepare).with("INSERT IGNORE INTO currencies (currency_code) VALUES(?)")
          expect(@statement).to receive(:execute).with("USD")
          @instance.add_new_rates?(@rates)
        end

        it "inserts the rates into the database" do
          expect(@mysql_client).to receive(:prepare).with(multiline_string(%{
            INSERT IGNORE INTO exchange_rates_against_base_currency
            (rate, date_recorded, currency_id)
            VALUES(?, ?, (SELECT id FROM currencies WHERE currency_code=?))
          }))
          expect(@statement).to receive(:execute).with(1.456, "2018-10-10", "USD")
          @instance.add_new_rates?(@rates)
        end
      end
    end
  end

  describe "perform" do
    before(:each) do
      @latest_rates = [ { :rate => 1.111, currency_code: "USD", :date => "2018-01-01" } ]
      allow(@instance).to receive(:fetch_latest_rates).and_return(@latest_rates)
      allow(@instance).to receive(:add_new_rates?).and_return(true)
      allow(@instance).to receive(:perform_in)
      allow(TimezonedDates).to receive(:today).and_return(Date.new(2018, 01, 04))
      allow(ExchangeRates).to receive(:get_latest_rate_date).and_return(Date.new(2018, 01, 03))
    end

    describe "when todays rates have not been fetched" do
      describe "when it fails to add new rates" do
        before(:each) do
          allow(@instance).to receive(:add_new_rates?).and_return(false)
        end

        describe "when the attempt count is less than 5" do
          it "logs an attempt with the attempt count" do
            expect(ForeignExchangeAPILogger).to receive(:info).with({
              "message" => "Performing update_exchange_rates job attempt #1"
            })
            @instance.perform()
          end

          it "calls perform_in to retry in 30 seconds" do
            expect(@instance).to receive(:perform_in).with(30, 2)
            @instance.perform()
          end
        end

        describe "when the attempt count is 5 or greated" do
          it "logs an attempt with the attempt count" do
            expect(ForeignExchangeAPILogger).to receive(:info).with({
              "message" => "Performing update_exchange_rates job attempt #5"
            })
            @instance.perform(5)
          end

          it "logs an error for being unable to update the rates" do
            expect(ForeignExchangeAPILogger).to receive(:error).with({
              "message" => "Failed to update exchange rates after 5 attempts"
            })
            @instance.perform(5)
          end
        end
      end

      describe "when it successfully adds the new rates" do
        it "logs a success message" do
          expect(ForeignExchangeAPILogger).to receive(:info).with({
            "message" => "Successfully updated exchange rates after 1 attempts"
          })
          @instance.perform()
        end
      end
    end

    describe "when todays rates have been fetched" do
      before(:each) do
        allow(ExchangeRates).to receive(:get_latest_rate_date).and_return(Date.new(2018, 01, 04))
      end

      it "logs a message saying rates are up to date" do
        expect(ForeignExchangeAPILogger).to receive(:info).with({
          "message" => "Already up to date"
        })
        @instance.perform()
      end
    end
  end
end
