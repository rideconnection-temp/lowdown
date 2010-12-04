require 'point_in_time/point_in_time'
ActiveRecord::Base.class_eval { include VersionFu }