require_relative "database.rb"

describe Database do
  before(:each) do
    @client = instance_double(Mysql2::Client)
    allow(ForeignExchangeAPIConfig).to receive(:get).with("DB_HOST", "localhost").and_return("localhost")
    allow(ForeignExchangeAPIConfig).to receive(:get).with("DB_UNAME", "root").and_return("root")
    allow(ForeignExchangeAPIConfig).to receive(:get).with("DB_PASS").and_return("")
    allow(ForeignExchangeAPIConfig).to receive(:get).with("DB_PORT", "3306").and_return("3306")
    allow(Mysql2::Client).to receive(:new).and_return(@client)
  end

  describe "get_client" do
    describe "when it successfully instantiates the Mysql2::Client" do
      it "sets up the database connection with the correct config" do
        expect(Mysql2::Client).to receive(:new).with(
          :host => "localhost",
          :username => "root",
          :password => "",
          :port => 3306,
          :database => "foreign_exchange"
        )
        Database::get_client
      end

      it "returns the client instance" do
        client = Database::get_client
        expect(client).to be(Database::get_client)
      end
    end

    describe "when it fails to instantiate Mysql2::Client" do
      before(:each) do
        Database.client nil
        @error = StandardError.new("MySQL Error")
        allow(Mysql2::Client).to receive(:new).and_raise(@error)
        allow(ForeignExchangeAPILogger).to receive(:error)
      end

      it "logs the error" do
        expect(ForeignExchangeAPILogger).to receive(:error).with({
          "message" => "Error connecting to MySQL database",
          "params" => {
            "host" => "localhost",
            "username" => "root",
            "password" => "REDACTED",
            "port" => 3306,
            "database" => "foreign_exchange"
          }
        })
        begin
          Database::get_client
          expect(true).to eq(false)
        rescue StandardError => e
        end
      end

      it "raises the error" do
        begin
          Database::get_client
          expect(true).to eq(false)
        rescue StandardError => e
          expect(e).to be(@error)
        end
      end
    end
  end
end
