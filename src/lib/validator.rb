module Validator
  def self.validate_amount (amount)
    return amount > 0
  end

  def self.validate_date (date)
    format_ok = date.match(/\d{4}-\d{2}-\d{2}/)
    parseable = Date.strptime(date, "%Y-%m-%d") rescue false
    return !!(format_ok && parseable)
  end

  def self.validate_currency_code (currency_code)
    return currency_code.match(/^[A-Z]{3}$/) != nil
  end
end
