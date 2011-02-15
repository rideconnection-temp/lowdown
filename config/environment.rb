# Load the rails application
require File.expand_path('../application', __FILE__)

# Done to avoid a lookup table just for trip purposes. Move to a model if that's felt to be better
POSSIBLE_TRIP_PURPOSES = ["Life-Sustaining Medical", "Medical", "Nutrition", "Personal/Support Services", "Recreation", "Shopping", "School/Work", "Volunteer Work"]

# Initialize the rails application
Lowdown::Application.initialize!
