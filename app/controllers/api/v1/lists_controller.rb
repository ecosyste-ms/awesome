class Api::V1::ListsController < Api::V1::ApplicationController
  def index
    scope = List.displayable

    if params[:project_id].present?
      if (project = misrouted_record(Project, params[:project_id], 'lists'))
        return render_project(project)
      end

      if params[:project_id].to_i.to_s == params[:project_id]
        @project = Project.find(params[:project_id])
        raise ActiveRecord::RecordNotFound if @project.has_blocked_topic?
        query = params.permit(:topic, :language, :sort, :order, :page, :per_page)
        redirect_to api_v1_project_lists_url(@project, query.to_h), status: :moved_permanently and return
      else
        @project = Project.find_by_slug!(params[:project_id])
        raise ActiveRecord::RecordNotFound if @project.has_blocked_topic?
      end

      scope = scope.where(id: @project.list_projects.select(:list_id))
    end

    if params[:topic].present?
      scope = scope.topic(params[:topic])
    end

    if params[:language].present?
      scope = scope.primary_language(params[:language])
    end

    if params[:sort].present? || params[:order].present?
      sort = sanitize_sort(List.sortable_columns)
      if params[:order] == 'asc'
        scope = scope.order(sort.asc.nulls_last)
      else
        scope = scope.order(sort.desc.nulls_last)
      end
    else
      scope = scope.order_by_stars
    end

    @pagy, @lists = pagy_countless(scope)
    fresh_when(@lists, public: true)
  end

  def show
    if params[:id].to_i.to_s == params[:id]
      @list = List.find(params[:id])
      redirect_to api_v1_list_url(@list), status: :moved_permanently
    else
      render_list(List.find_by_slug!(params[:id]))
    end
  end

  def lookup
    raise ActionController::BadRequest.new('URL is required') unless params[:url].present?
    @list = List.find_by(url: params[:url].downcase)
    if @list.nil?
      @list = List.create(url: params[:url].downcase)
      @list.sync_async
    end
    @list.sync_async if @list.last_synced_at.nil? || @list.last_synced_at < 1.day.ago
    fresh_when(@list, public: true)
  end
end
