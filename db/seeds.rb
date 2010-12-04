# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
require 'csv'

User.create(:name => 'Admin', :email => 'admin@example.com', :password => 'password', :password_confirmation => 'password')

CSV.foreach(File.join(Rails.root,'db','seeds','providers.csv'),headers: true) do |r|
  p = Provider.find_or_initialize_by_routematch_id(r['routematch_id'])
  p.update_attributes!(r.to_hash)
end
