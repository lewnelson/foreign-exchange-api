require_relative "validator.rb"

describe Validator do
  describe "validate_amount" do
    it "returns false when amount is 0" do
      expect(Validator::validate_amount(0)).to be(false)
    end

    it "returns false when amount is less than 0" do
      expect(Validator::validate_amount(-1)).to be(false)
    end

    it "returns true when amount is an integer greater than 0" do
      expect(Validator::validate_amount(1)).to be(true)
    end

    it "returns true when amount is an float greater than 0" do
      expect(Validator::validate_amount(1.123)).to be(true)
    end
  end

  describe "validate_date" do
    it "returns true when valid date in valid format" do
      expect(Validator::validate_date("2018-01-29")).to be(true)
    end

    it "returns false when valid date in invalid format" do
      expect(Validator::validate_date("29-01-2018")).to be(false)
    end

    it "returns false when valid format with invalid date" do
      expect(Validator::validate_date("2018-13-29")).to be(false)
    end
  end

  describe "validate_currency_code" do
    it "returns true when currency_code is valid" do
      expect(Validator::validate_currency_code("ABC")).to be(true)
    end

    it "returns false when currency_code is invalid" do
      expect(Validator::validate_currency_code("ABCD")).to be(false)
    end
  end
end
