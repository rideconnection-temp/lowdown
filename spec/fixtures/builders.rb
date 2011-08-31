require 'fixjour'
require 'faker'

Fixjour :verify => false do
  define_builder(Run) do |klass, overrides|
    klass.new({
      
    })
  end
  
  define_builder(Trip) do |klass, overrides|    
    id = UUIDTools::UUID.timestamp_create().to_s
    klass.new({
      :run         => new_run,
      :bulk_import => true,
      :id => id,
      :base_id => id
    })
  end
end