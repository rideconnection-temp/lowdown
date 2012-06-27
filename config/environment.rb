# Load the rails application
require File.expand_path('../application', __FILE__)

# Done to avoid a lookup table just for trip purposes. Move to a model if that's felt to be better
POSSIBLE_TRIP_PURPOSES = ["Life-Sustaining Medical", "Medical", "Nutrition", "Personal/Support Services", "Recreation", "School/Work", "Shopping", "Volunteer Work"]

TRIP_PURPOSE_TO_SUMMARY_PURPOSE = {
"Adult Daycare" => "Personal/Support Services",
"Childcare" => "School/Work",
"Employment" => "School/Work",
"Life Sustaining Medical" => "Life-Sustaining Medical",
"Medical" => "Medical",
"Nutrition" => "Nutrition",
"Personal Business" => "Personal/Support Services",
"Recreation" => "Recreation",
"Training / School" => "School/Work",
"Shopping" => "Shopping",
"Supportive Services" => "Personal/Support Services",
"Volunteer Work" => "Volunteer Work",
"Life Sustaining ACS" => "Life-Sustaining Medical",
"" => "Unspecified",
nil => "Unspecified"
    }

TRIP_COLLECTION_METHODS = %w{trips summary_rows none}
RUN_COLLECTION_METHODS  = %w{runs summary trips none}
COST_COLLECTION_METHODS = %w{summary trips none}

EMAIL_FROM = "apps@rideconnection.com"

# Initialize the rails application
Lowdown::Application.initialize!
