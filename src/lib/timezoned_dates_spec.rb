require_relative "timezoned_dates.rb"

describe TimezonedDates do
  describe "today" do
    it "returns the local date" do
      expect(TimezonedDates::today("+01:00")).to eq(Time.now.getlocal("+01:00").to_date)
    end
  end
end
