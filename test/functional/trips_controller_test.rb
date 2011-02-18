require 'test_helper'
require 'capybara/rails'
require 'capybara/dsl'

class TripsControllerTest < ActionController::TestCase
  include Capybara
  fixtures :users

  test "should accept imports" do
    Capybara.default_selector = :xpath

    visit "/trips/import"

    dir = File.dirname(__FILE__)
    csv = File.join(dir, 'sample.csv')
    attach_file('file-import', csv)
    click_button('Import')

    visit "/trips/list"

    assert page.has_selector?('//div[@id="flash"]')

    assert page.find('//h2[@id="result-count"]').text =~ /0 trips/

    fill_in "query[start_date]", :with => "2010-9-1"
    fill_in "query[end_date]", :with => "2010-9-1"

    click_button("Search")
    assert page.find('//h2[@id="result-count"]').text =~ /1 trip/
  end
end
