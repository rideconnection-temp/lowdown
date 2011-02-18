class RunsController < ApplicationController
  before_filter :require_user
  before_filter :require_admin_user, :except=>[:index, :show]
  
  def index
    @runs = Run.current_versions.paginate :page => params[:page], :per_page => 30, :order => 'created_at desc, routematch_id asc'
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



end
