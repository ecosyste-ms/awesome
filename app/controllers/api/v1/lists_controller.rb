class Api::V1::ListsController < Api::V1::ApplicationController
  def index
    scope = List.displayable

    if params[:project_id].present?
      if params[:project_id].to_i.to_s == params[:project_id]
        @project = Project.find(params[:project_id])
        redirect_to api_v1_project_lists_url(@project), status: :moved_permanently
      else
        @project = Project.find_by_slug!(params[:project_id])
      end

      scope = scope.joins(:projects).where(projects: { id: @project.id })
    end

    if params[:topic].present?
      scope = scope.topic(params[:topic])
    end

    if params[:language].present?
      scope = scope.primary_language(params[:language])
    end

    if params[:sort].present? || params[:order].present?
      sort = params[:sort].presence || 'updated_at'
      if params[:order] == 'asc'
        scope = scope.order(Arel.sql(sort).asc.nulls_last)
      else
        scope = scope.order(Arel.sql(sort).desc.nulls_last)
      end
    else
      scope = scope.order_by_stars
    end

    @pagy, @lists = pagy_countless(scope)
  end

  def show
    if params[:id].to_i.to_s == params[:id]
      @list = List.find(params[:id])
      redirect_to api_v1_list_url(@list), status: :moved_permanently
    else
      @list = List.find_by_slug!(params[:id])
    end
  end

  def lookup
    @list = List.find_by(url: params[:url].downcase)
    if @list.nil?
      @project = List.create(url: params[:url].downcase)
      @list.sync_async
    end
    @list.sync_async if @list.last_synced_at.nil? || @list.last_synced_at < 1.day.ago
  end
end