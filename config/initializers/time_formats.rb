Date::DATE_FORMATS[:default] = '%Y-%m-%d'
Date::DATE_FORMATS[:long] = '%B %d, %Y'
Time::DATE_FORMATS[:pretty] = lambda { |time| time.strftime("%a, %b %e at %l:%M") + time.strftime("%p").downcase }
