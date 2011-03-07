class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_at
  attr_accessor :end_at

  def convert_date(obj, base)
    return DateTime.new(obj["#{base}(1i)"].to_i,obj["#{base}(2i)"].to_i,obj["#{base}(3i)"].to_i)
  end

  def initialize(params)
    if params
      if params["start_at"]
        splitstart = params["start_at"].split("-")
        @start_at = monthify({:yyyy => splitstart[0].to_i, :mm => splitstart[1].to_i})
      end
      if params["end_at"]
        splitend = params["end_at"].split("-")
        @end_at = monthify({:yyyy => splitend[0].to_i, :mm => splitend[1].to_i, :monthend => true})
      end
    end
  end

  def persisted?
    false
  end

  def conditions
    d = {}
    if start_at
      d[:start_at] = start_at..end_at
      d[:end_at] = start_at..end_at
    end
    d
  end
end

# end_of_month was dropped from Rails 3, really?
# FIXME - Adding this to application_helper.rb doesn't make it available to models. where's the best place for this to live?
class Date
   def self.last_day_of_the_month(yyyy, mm)
     new(yyyy, mm, -1)
   end
end
 
def monthify(options={})
   today = Date.today
   default_options = {:yyyy => today.year, :mm => today.month, :monthend => false}
   options = default_options.merge options
   dd = (options[:monthend]) ? Date.last_day_of_the_month(options[:yyyy].to_i, options[:mm].to_i) : Date.new(options[:yyyy], options[:mm], 1)
   return dd
end

class RunsController < ApplicationController
  before_filter :require_user
  before_filter :require_admin_user, :except=>[:index, :show]
  
  def index
    @query = Query.new(params[:query])
    if @query.conditions.empty?
      @query.end_at = DateTime.now
      @query.start_at = @query.end_at.beginning_of_month
      flash[:notice] = 'No search criteria set - showing default (current month)'
    end

    @runs = Run.current_versions.paginate :page => params[:page], :per_page => 30, :conditions => @query.conditions

  end
  
  def create
    @run = Run.new(params[:run])
  end

  def show
    @run = Run.find(params[:id])
  end

  def update
    @run = Run.current_versions.find(params[:run][:id])
    @run.update_attributes(params[:run]) ?
      redirect_to(:action=>:show, :id=>@run) : render(:action => :show)
  end

  def bulk_update
    updated = 0

    @query = Query.new(params[:query])
    if @query.conditions.empty?
      flash[:error] = "Cannot update without conditions"
    else
      for run in Run.current_versions :conditions => @query.conditions
        updated += 1
        run.complete = true
        run.save!
      end
      flash[:notice] = "Updated #{updated} records"

    end
    redirect_to :action=>:index
  end

end
