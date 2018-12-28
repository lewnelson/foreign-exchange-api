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
          :database => "foreign_exchange",
          :reconnect => true
        )
        Database::get_client
      end

      it "returns the client instance" do
        client = Database::get_client
        expect(client).to be(Database::get_client)
      end
    end
  end
end
