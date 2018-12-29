require_relative "currencies.rb"
require_relative "database.rb"
require_relative "cache.rb"

module ExchangeRates
  extend self

  class ExchangeRatesInputError < StandardError
  end

  def get_latest_rate_date
    cached = Cache::get_transport.get("ExchangeRates::get_latest_rate_date")
    if cached
      return Date.strptime(cached.to_s, "%Y-%m-%d")
    end

    db_client = Database.get_client
    result = db_client.query(%{
      SELECT date_recorded FROM exchange_rates_against_base_currency
      ORDER BY date_recorded DESC
      LIMIT 1
    })

    value = result.first["date_recorded"] rescue "0000-01-01"
    Cache::get_transport.set("ExchangeRates::get_latest_rate_date", value, 60 * 5)
    return Date.strptime(value.to_s, "%Y-%m-%d")
  end

  def get_earliest_rate_date
    cached = Cache::get_transport.get("ExchangeRates::get_earliest_rate_date")
    if cached
      return Date.strptime(cached.to_s, "%Y-%m-%d")
    end

    db_client = Database.get_client
    result = db_client.query(%{
      SELECT date_recorded FROM exchange_rates_against_base_currency
      ORDER BY date_recorded ASC
      LIMIT 1
    })

    value = result.first["date_recorded"] rescue "0000-01-01"
    Cache::get_transport.set("ExchangeRates::get_earliest_rate_date", value, 60 * 5)
    return Date.strptime(value.to_s, "%Y-%m-%d")
  end

  def check_currency_exists (currency_code, date)
    if !Currencies.currency_exists?(currency_code, date)
      raise ExchangeRatesInputError.new("Currency code '#{currency_code}' does not exist for date '#{date}'")
    end
  end

  def check_date_is_in_range (date)
    earliest_rate_date = get_earliest_rate_date
    if date < earliest_rate_date
      raise ExchangeRatesInputError.new("Date '#{date}' preceeds earliest available date - '#{earliest_rate_date}'")
    end

    latest_rate_date = get_latest_rate_date
    if date > latest_rate_date
      raise ExchangeRatesInputError.new("Date '#{date}' cannot exceed latest available date - '#{latest_rate_date}'")
    end
  end

  def get_currency_rate (currency_code, date)
    cached = Cache::get_transport.get("ExchangeRates::get_currency_rate__#{currency_code}_#{date}")
    if cached
      return cached.to_f
    end

    db_client = Database.get_client
    statement = db_client.prepare(%{
      SELECT e_rates.rate AS rate
      FROM exchange_rates_against_base_currency AS e_rates
      LEFT JOIN currencies ON e_rates.currency_id=currencies.id
      WHERE e_rates.date_recorded=? AND currencies.currency_code=?
      LIMIT 1
    })
    result = statement.execute(date, currency_code)
    rate = result.first["rate"]
    if rate == nil
      raise StandardError.new("Unable to find rate for currency_code='#{currency_code}' on date='#{date}'")
    end

    Cache::get_transport.set("ExchangeRates::get_currency_rate__#{currency_code}_#{date}", rate, 60 * 5)
    return rate
  end

  def at (date, from_currency_code, to_currency_code)
    check_date_is_in_range(date)
    check_currency_exists(from_currency_code, date)
    check_currency_exists(to_currency_code, date)
    return get_currency_rate(to_currency_code, date).to_f / get_currency_rate(from_currency_code, date).to_f
  end

  def exchange_currency (date, from_currency_code, to_currency_code, amount)
    return (at(date, from_currency_code, to_currency_code) * amount).round(2)
  end
end
