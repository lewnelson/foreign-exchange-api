require "mysql2"
require_relative "logger.rb"
require_relative "config.rb"

class Database
  def self.client (v)
    @client = v
  end

  def self.get_client
    if !@client
      begin
        host = ForeignExchangeAPIConfig::get("DB_HOST", "localhost")
        username = ForeignExchangeAPIConfig::get("DB_UNAME", "root")
        password = ForeignExchangeAPIConfig::get("DB_PASS")
        port = ForeignExchangeAPIConfig::get("DB_PORT", "3306").to_i
        database = "foreign_exchange"
        @client = Mysql2::Client.new(
          :host => host,
          :username => username,
          :password => password,
          :port => port,
          :database => database
        )
      rescue StandardError => e
        ForeignExchangeAPILogger::error({
          "message" => "Error connecting to MySQL database",
          "params" => {
            "host" => host,
            "username" => username,
            "password" => "REDACTED",
            "port" => port,
            "database" => database
          }
        })
        raise e
      end
    end

    return @client
  end
end
