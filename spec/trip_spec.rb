require 'spec_helper'

describe Trip do
  describe "before validation" do
    context "when creating trips that track run data on a per-trip basis" do
      attr_reader :trip_1, :trip_2, :trip_3, :allocation_1, :attrs
      
      before do
        @attrs = {
          :trip_1 => {
            :routematch_share_id => 1,
            :date => '2010-11-7',
            :start_at => "Tue, 07 Sep 2010 09:45:00 UTC +00:00", 
            :end_at   => "Tue, 07 Sep 2010 10:00:00 UTC +00:00",
            :odometer_start => 0,
            :odometer_end => 20,
            :fare => 24.00,
            :estimated_trip_distance_in_miles => 7.0,
            :result_code => 'COMP'
          },
          :trip_2 => {
            :routematch_share_id => 1,
            :date => '2010-11-7',
            :start_at => "Tue, 07 Sep 2010 09:45:00 UTC +00:00", 
            :end_at   => "Tue, 07 Sep 2010 10:00:00 UTC +00:00",
            :odometer_start => 0,
            :odometer_end => 20,
            :fare => 6.00,
            :estimated_trip_distance_in_miles => 7.0,
            :result_code => 'COMP'
          },
          :trip_3 => {
            :routematch_share_id => 2,
            :date => '2010-11-7',
            :start_at => "Tue, 07 Sep 2010 09:45:00 UTC +00:00", 
            :end_at   => "Tue, 07 Sep 2010 10:00:00 UTC +00:00",
            :odometer_start => 0,
            :odometer_end => 20,
            :fare => 30.00,
            :estimated_trip_distance_in_miles => 7.0,
            :result_code => 'COMP'
          },
          :allocation_1 => {
            :run_collection_method => 'trips'
          }
        }
        
        @allocation_1 = create_allocation attrs[:allocation_1]
        @trip_1 = create_trip attrs[:trip_1].merge(:allocation => allocation_1)
        @trip_2 = create_trip attrs[:trip_2].merge(:allocation => allocation_1) 
        @trip_3 = create_trip attrs[:trip_3].merge(:allocation => allocation_1)  
        
        [trip_1, trip_2, trip_3].each &:reload
      end

      it "apportions trips that are shared upon creation" do
        trip_1.apportioned_duration.should eq(7.5)
        trip_1.apportioned_mileage.should eq(10)
        trip_1.apportioned_fare.should eq(15)
        trip_2.apportioned_duration.should eq(7.5)
        trip_2.apportioned_mileage.should eq(10)
        trip_2.apportioned_fare.should eq(15)
      end

      it "apportions trips that are not shared upon creation" do
        trip_3.apportioned_duration.should eq(15)
        trip_3.apportioned_mileage.should eq(20)
        trip_3.apportioned_fare.should eq(30)
      end
      
      it "reapportions the all affected trips when share is updated" do
        # update the 2nd trip's routematch share id to trip 3's
        trip_2.routematch_share_id = trip_3.routematch_share_id
        trip_2.save
        [trip_1, trip_2, trip_3].each &:reload

        trip_1.apportioned_duration.should eq(15)
        trip_1.apportioned_mileage.should eq(20)
        trip_1.apportioned_fare.should eq(24)
        trip_2.apportioned_duration.should eq(7.5)
        trip_2.apportioned_mileage.should eq(10)
        trip_2.apportioned_fare.should eq(18)
        trip_3.apportioned_duration.should eq(7.5)
        trip_3.apportioned_mileage.should eq(10)
        trip_3.apportioned_fare.should eq(18)
      end
    end
  end
end
