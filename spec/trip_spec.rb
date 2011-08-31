require 'spec_helper'

describe Trip do
  describe "before validation" do
    context "when changing from one routeshare to another" do
      attr_reader :trip_1, :trip_2, :trip_3, :attrs
      
      before do
        @attrs = {
          :trip_1 => {
            :routematch_share_id => 1,
            :start_at => "Tue, 07 Sep 2010 09:45:00 UTC +00:00", 
            :end_at   => "Tue, 07 Sep 2010 10:03:00 UTC +00:00",
            :odometer_start => 101714,
            :odometer_end => 101721,
            :fare => 24.54,
            :estimated_trip_distance_in_miles => 6.88
          },
          :trip_2 => {
            :routematch_share_id => 1,
            :start_at => "Tue, 07 Sep 2010 09:45:00 UTC +00:00", 
            :end_at   => "Tue, 07 Sep 2010 10:03:00 UTC +00:00",
            :odometer_start => 101714,
            :odometer_end => 101721,
            :fare => 9.0,
            :estimated_trip_distance_in_miles => 7.0
          },
          :trip_3 => {
            :routematch_share_id => 2,
            :start_at => "Wed, 07 Sep 2010 09:33:00 UTC +00:00", 
            :end_at   => "Wed, 07 Sep 2010 09:44:00 UTC +00:00",
            :odometer_start => 137599,
            :odometer_end => 137604,
            :fare => 12.3,
            :estimated_trip_distance_in_miles => 5.0
          }
        }
        
        @trip_1 = create_trip attrs[:trip_1]
        @trip_2 = create_trip attrs[:trip_2] 
        @trip_3 = create_trip attrs[:trip_3]
        
        [trip_1, trip_2, trip_3].each &:reload
        
        # update the 2nd trip's routematch share id to trip 3's
        trip_2.routematch_share_id = trip_3.routematch_share_id
        trip_2.should_run_callbacks = true
        # puts "======SAVING====="
        trip_2.save
        # puts "======SAVED++++++"
      end
      
      it "reapportions the old routeshare's trips" do
        # puts "TRIP 1 ATTRS #{trip_1.reload.attributes.inspect}"
        pending "callbacks are not being run, cannot isolate test case"
      end
      
      it "reapportions the new routeshare's trips" do
        # puts "TRIP 2 ATTRS #{trip_1.reload.attributes.inspect}"
        pending "callbacks are not being run, cannot isolate test case"
      end
    end
  end
end
