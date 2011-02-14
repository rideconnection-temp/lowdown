# Load the rails application
require File.expand_path('../application', __FILE__)

# Done to avoid a lookup table just for trip purposes. Move to a model if that's felt to be better
POSSIBLE_TRIP_PURPOSES = ["Medical", "Life-Sustaining Medical", "Personal/Support Services", "Shopping", "School/Work", "Volunteer Work", "Recreation", "Nutrition"]

# Initialize the rails application
Lowdown::Application.initialize!
