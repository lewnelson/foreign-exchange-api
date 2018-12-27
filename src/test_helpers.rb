require "sinatra"
require "rack/test"

module ForeignExchangeAPITestHelpers
  def self.multiline_string_to_array (s)
    a = Array.new
    s.split("\n").each do |line|
      line.strip!
      a << line
    end

    return a
  end

  def self.multiline_string_to_single_line (s)
    a = multiline_string_to_array(s)
    return a.join("")
  end

  def self.get_browser (new_browser = true)
    if @browser && !new_browser
      return @browser
    end

    @browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
    return @browser
  end
end

RSpec::Matchers.define :multiline_string do |s|
  match { |actual|
    ForeignExchangeAPITestHelpers::multiline_string_to_single_line(s) == ForeignExchangeAPITestHelpers::multiline_string_to_single_line(actual)
  }
end
