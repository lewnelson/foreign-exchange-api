STDOUT.sync = true
require_relative "../jobs/update_exchange_rates.rb"
UpdateExchangeRates.new.perform()
