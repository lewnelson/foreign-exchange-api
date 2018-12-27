require "json"
require_relative "database.rb"
require_relative "cache.rb"

module Currencies
  extend self

  def get_all (date)
    cached = Cache::get_transport.get("Currencies::get_all__#{date}")
    if cached
      return JSON.parse(cached)
    end

    db_client = Database.get_client
    statement = db_client.prepare(%{
      SELECT currencies.currency_code FROM exchange_rates_against_base_currency
      RIGHT JOIN currencies ON exchange_rates_against_base_currency.currency_id=currencies.id
      WHERE exchange_rates_against_base_currency.date_recorded=?
    })
    results = statement.execute(date).to_a
    currencies = results.map { |row| row["currency_code"] } rescue Array.new
    if currencies.length > 0
      Cache::get_transport.set("Currencies::get_all__#{date}", currencies, 60 * 5)
    end

    return currencies
  end

  def currency_exists? (currency_code, date)
    return get_all(date).include?(currency_code)
  end
end
