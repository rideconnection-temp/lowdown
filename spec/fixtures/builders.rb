require 'fixjour'
require 'faker'

Fixjour :verify => false do
  define_builder(Run) do |klass, overrides|
    klass.new({
      
    })
  end

  define_builder(Allocation) do |klass, overrides|
    klass.new({
      :name => 'name',
      :admin_ops_data => 'Prohibited',
      :vehicle_maint_data => 'Prohibited'
    })
  end
  
  define_builder(Trip) do |klass, overrides|    
    klass.new({
      :run         => new_run
    })
  end
end
