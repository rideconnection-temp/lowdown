# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
require 'csv'

User.create(:name => 'Admin', :email => 'admin@example.com', :password => 'password', :password_confirmation => 'password')

Provider.destroy_all
CSV.foreach(File.join(Rails.root,'db','seeds','providers.csv'),headers: true) do |r|
  p = Provider.find_or_initialize_by_routematch_id(r['routematch_id'])
  p.update_attributes!(r.to_hash)
end

Project.destroy_all
CSV.foreach(File.join(Rails.root,'db','seeds','projects.csv'),headers: true) do |r|
  p = Project.new
  p.update_attributes!(r.to_hash)
end

Allocation.destroy_all
CSV.foreach(File.join(Rails.root,'db','seeds','allocations.csv'),headers: true) do |r|
  p = Allocation.new
  p.name = r['name']
  proj = Project.find_by_name(r['project_name'])
  raise "No project '#{r['project_name']}'" if proj.nil?
  p.project_id = proj.id
  prov = Provider.find_by_name(r['provider_name'])
  raise "No provider '#{r['provider_name']}'" if prov.nil?
  p.provider_id = prov.id
  p.group_trip = true
  p.county = r['county']
  p.routematch_override = r['routematch_override']
  p.routematch_provider_code = r['routematch_provider_code']
  p.trip_collection_method = r['trip_collection_method']
  p.run_collection_method = r['run_collection_method']
  p.cost_collection_method = r['cost_collection_method']
  p.save!
end
