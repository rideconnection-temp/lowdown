require 'test_helper'
require 'capybara/rails'
require 'capybara/dsl'

class TripsControllerTest < ActionController::TestCase
  include Capybara

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

    select('2010', :from => 'query[start_date(1i)]')
    select('2010', :from => 'query[end_date(1i)]')
    select('September', :from => 'query[start_date(2i)]')
    select('September', :from => 'query[end_date(2i)]')
    select('1', :from => 'query[start_date(3i)]')
    select('1', :from => 'query[end_date(3i)]')

    click_button("Search")
    assert page.find('//h2[@id="result-count"]').text =~ /1 trip/
  end
end
