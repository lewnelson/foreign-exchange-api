require "sinatra"
require "json"
require_relative "lib/currencies.rb"
require_relative "lib/exchange_rates.rb"
require_relative "lib/validator.rb"
require_relative "lib/logger.rb"
require_relative "lib/config.rb"

class Sinatra::Base
  def validate_input (date, from_currency_code, to_currency_code, amount = nil, amount_required = false)
    errors = Array.new
    if !Validator::validate_date(date)
      errors.push("Invalid param `date` '#{date}', must be in the format YYYY-MM-DD")
    end

    if !Validator::validate_currency_code(from_currency_code)
      errors.push("Invalid param `from_currency_code` '#{from_currency_code}', must conform to ISO_4217")
    end

    if !Validator::validate_currency_code(to_currency_code)
      errors.push("Invalid param `to_currency_code` '#{to_currency_code}', must conform to ISO_4217")
    end

    if amount_required
      if !Validator::validate_amount(amount)
        errors.push("Invalid param `amount` '#{params[:amount]}', must be a number greater than 0")
      end
    end

    return errors
  end

  get "/exchange-rate" do
    start = Time.now
    date = params[:date].to_s
    from_currency_code = params[:from_currency_code].to_s
    to_currency_code = params[:to_currency_code].to_s
    errors = validate_input(date, from_currency_code, to_currency_code)

    if errors.length > 0
      status 400
      content_type :json
      body({ :errors => errors }.to_json)
      return
    end

    begin
      exchanged_rate = ExchangeRates::at(
        Date.strptime(date, "%Y-%m-%d"),
        from_currency_code,
        to_currency_code
      )
      content_type :json
      cache_control(:max_age => 60 * 60, :public => true, :must_revalidate => true)
      body({ :result => exchanged_rate }.to_json)
      ForeignExchangeAPILogger::timing(start, {
        "route" => "GET /exchange-rate",
        "params" => params
      })
    rescue ExchangeRates::ExchangeRatesInputError => e
      status 400
      content_type :json
      body({ :errors => [ e.message ] }.to_json)
    rescue StandardError => e
      if !ForeignExchangeAPIConfig.is_production?
        raise e
      end
      status 500
      content_type :json
      body({ :errors => [ "internal server error" ] }.to_json)
    end
  end

  get "/exchange-currency" do
    start = Time.now
    date = params[:date].to_s
    amount = params[:amount].to_f
    from_currency_code = params[:from_currency_code].to_s
    to_currency_code = params[:to_currency_code].to_s
    errors = validate_input(date, from_currency_code, to_currency_code, amount, true)

    if errors.length > 0
      status 400
      content_type :json
      body({ :errors => errors }.to_json)
      return
    end

    begin
      exchanged_rate = ExchangeRates::exchange_currency(
        Date.strptime(date, "%Y-%m-%d"),
        from_currency_code,
        to_currency_code,
        amount
      )
      content_type :json
      cache_control(:max_age => 60 * 60, :public => true, :must_revalidate => true)
      body({ :result => exchanged_rate }.to_json)
      ForeignExchangeAPILogger::timing(start, {
        "route" => "GET /exchange-currency",
        "params" => params
      })
    rescue ExchangeRates::ExchangeRatesInputError => e
      status 400
      content_type :json
      body({ :errors => [ e.message ] }.to_json)
    rescue StandardError => e
      if !ForeignExchangeAPIConfig.is_production?
        raise e
      end
      status 500
      content_type :json
      body({ :error => "internal server error" }.to_json)
    end
  end

  get "/supported-currencies" do
    start = Time.now
    errors = Array.new
    date = params[:date].to_s
    if !Validator::validate_date(date)
      errors.push("Invalid param `date` '#{date}', must be in the format YYYY-MM-DD")
    end

    if errors.length > 0
      status 400
      content_type :json
      body({ :errors => errors }.to_json)
      return
    end

    content_type :json
    cache_control(:max_age => 60 * 15, :public => true, :must_revalidate => true)
    body({ :result => Currencies::get_all(date) }.to_json)
    ForeignExchangeAPILogger::timing(start, { "route" => "GET /supported-currencies" })
  end

  get "/earliest-supported-date" do
    start = Time.now
    content_type :json
    cache_control(:max_age => 60 * 60, :public => true, :must_revalidate => true)
    body({ :result => ExchangeRates::get_earliest_rate_date.strftime("%Y-%m-%d") }.to_json)
    ForeignExchangeAPILogger::timing(start, { "route" => "GET /earliest-supported-date" })
  end

  get "/latest-supported-date" do
    start = Time.now
    content_type :json
    cache_control(:max_age => 60 * 5, :public => true, :must_revalidate => true)
    body({ :result => ExchangeRates::get_latest_rate_date.strftime("%Y-%m-%d") }.to_json)
    ForeignExchangeAPILogger::timing(start, { "route" => "GET /latest-supported-date" })
  end
end
