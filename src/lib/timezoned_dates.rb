module TimezonedDates
  # Gets the date for a specified timezone
  def self.today (offset)
    return Time.now.getlocal(offset).to_date
  end
end
