module ForeignExchangeAPIConfig
  def self.get (key, fallback = "")
    return ENV[key].length > 0 ? ENV[key] : fallback
  end

  def self.is_production?
    return get("RACK_ENV") == "production"
  end
end
