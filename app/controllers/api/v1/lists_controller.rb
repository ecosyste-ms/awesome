class Api::V1::ListsController < Api::V1::ApplicationController
  def index
    scope = List.displayable

    if params[:project_id].present?
      scope = scope.joins(:projects).where(projects: { id: params[:project_id] })
    end

    if params[:topic].present?
      scope = scope.where('repository ->> \'topics\' ILIKE ?', "%#{params[:topic]}%")
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
      scope = scope.order(@sort = Arel.sql("(lists.repository ->> 'stargazers_count')::text::integer").desc.nulls_last)
    end

    @pagy, @lists = pagy(scope)
  end

  def show
    @list = List.find(params[:id])
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