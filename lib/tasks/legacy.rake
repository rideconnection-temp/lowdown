namespace :legacy do
  desc 'Load legacy data into database'
  task :load do
    legacy_file = File.join(Rails.root, 'lib', 'legacy.rb')
    load(legacy_file) if File.exist?(legacy_file)
  end
end
