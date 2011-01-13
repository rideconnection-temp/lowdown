class SummaryController < ApplicationController

  def index
    @summaries = Summary.all
  end

  def show_create
    @providers = Provider.all
  end

end
