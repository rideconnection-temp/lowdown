class AddVolunteerRunToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :volunteer_run, :boolean

    reversible do |direction|
      direction.up do
        Run.where('id IN (SELECT run_id FROM trips where volunteer_trip = true)').update_all volunteer_run: true
      end
    end
  end
end
