class ListsController < ApplicationController
  def index
    scope = List.where.not(projects_count: nil).where('projects_count > 0').order(projects_count: :desc)
    @pagy, @lists = pagy(scope)
  end

  def show
    @list = List.find(params[:id])
  end
end