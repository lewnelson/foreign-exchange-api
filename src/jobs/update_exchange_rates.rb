require "net/http"
require "nokogiri"
require "timeout"
require_relative "../lib/exchange_rates.rb"
require_relative "../lib/database.rb"
require_relative "../lib/timezoned_dates.rb"
require_relative "../lib/logger.rb"

class UpdateExchangeRates
  def fetch_latest_rates (retries = 0)
    rates = []
    res = Net::HTTP.get_response(URI("https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist-90d.xml"))
    if res.is_a?(Net::HTTPSuccess)
      xml_doc  = Nokogiri::XML(res.body)
      namespace = "http://www.ecb.int/vocabulary/2002-08-01/eurofxref"
      xml_doc.at_xpath("//eurofxref:Cube", "eurofxref" => namespace).children.each do |date_node|
        date = date_node["time"]
        date_node.children.each do |currency_node|
          rates.push({ :date_recorded => date, :currency_code => currency_node[:currency], :rate => currency_node[:rate].to_f })
        end
      end
    else
      if retries < 10
        sleep 5
        return self.fetch_latest_rates(retries + 1)
      end
    end

    return rates
  end

  def add_new_rates? (rates)
    db_client = Database.get_client
    db_client.query("START TRANSACTION")
    rates.each do |rate|
      begin
        statement = db_client.prepare("INSERT IGNORE INTO currencies (currency_code) VALUES(?)")
        statement.execute(rate[:currency_code])

        statement = db_client.prepare(%{
          INSERT IGNORE INTO exchange_rates_against_base_currency
          (rate, date_recorded, currency_id)
          VALUES(?, ?, (SELECT id FROM currencies WHERE currency_code=?))
        })
        statement.execute(rate[:rate], rate[:date_recorded], rate[:currency_code])
      rescue Mysql2::Error => e
        ForeignExchangeAPILogger::error({
          "message" => "Failed SQL query inserting new rates",
          "error" => e
        })
        db_client.query("ROLLBACK")
        return false
      end
    end
    db_client.query("COMMIT")
    return true
  end

  def perform_in (t, attempt_count = 1)
    sleep t
    self.perform(attempt_count)
  end

  def perform (attempt_count = 1)
    ForeignExchangeAPILogger::info({
      "message" => "Performing update_exchange_rates job attempt ##{attempt_count}"
    })
    difference_in_days = (TimezonedDates.today("+01:00") - ExchangeRates::get_latest_rate_date).to_i
    if difference_in_days >= 1
      result = self.add_new_rates?(self.fetch_latest_rates)
      if !result && attempt_count < 5
        self.perform_in(30, attempt_count + 1)
      elsif !result
        ForeignExchangeAPILogger::error({
          "message" => "Failed to update exchange rates after #{attempt_count} attempts, next update in 15 minutes"
        })
        self.perform_in(60 * 15)
      else
        ForeignExchangeAPILogger::info({
          "message" => "Successfully updated exchange rates after #{attempt_count} attempts, next update in 15 minutes"
        })
        self.perform_in(60 * 15)
      end
    else
      ForeignExchangeAPILogger::info({
        "message" => "Already up to date, next update in 15 minutes"
      })
      self.perform_in(60 * 15)
    end
  end
end
