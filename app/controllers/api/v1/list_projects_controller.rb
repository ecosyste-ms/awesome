class Api::V1::ListProjectsController < ApplicationController
  def index
    if params[:list_id].to_i.to_s == params[:list_id]
      @list = List.find(params[:list_id])
      redirect_to api_v1_list_list_projects_url(@list), status: :moved_permanently
    else
      @list = List.find_by_slug!(params[:list_id])
    end
    @list_projects = @list.list_projects

    if params[:category].present?
      @list_projects = @list_projects.where(category: params[:category])
    end

    if params[:sub_category].present?
      @list_projects = @list_projects.where(sub_category: params[:sub_category])
    end

    @pagy, @list_projects = pagy_countless(@list_projects)
    fresh_when(@list_projects, public: true)
  end
end