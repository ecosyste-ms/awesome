class Api::V1::ListProjectsController < Api::V1::ApplicationController
  def index
    if (list = misrouted_record(List, params[:list_id], 'list_projects'))
      return render_list(list)
    end

    if params[:list_id].to_i.to_s == params[:list_id]
      @list = List.find(params[:list_id])
      query = params.permit(:category, :sub_category, :page, :per_page)
      redirect_to api_v1_list_list_projects_url(@list, query.to_h), status: :moved_permanently and return
    else
      @list = List.find_by_slug!(params[:list_id])
    end
    @list_projects = @list.list_projects.without_blocked_topics

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
