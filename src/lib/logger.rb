require "json"

module ForeignExchangeAPILogger
  def self.log (level, data)
    begin
      puts "#{Time::now}: #{level} - #{data.to_json}"
    rescue StandardError => e
      puts "#{Time::now}: LOG_ERROR - #{e.message}"
    end
  end

  def self.error (data)
    self.log("ERROR", data)
  end

  def self.warning (data)
    self.log("WARNING", data)
  end

  def self.info (data)
    self.log("INFO", data)
  end

  def self.timing (start, data)
    self.log("TIMING", {
      "data" => data,
      "time_elapsed" => (Time.now.to_f * 1000).to_i - (start.to_f * 1000).to_i
    })
  end
end
