class ListsController < ApplicationController
  def index
    scope = List.displayable

    if params[:topic].present?
      scope = scope.where('repository ->> \'topics\' ILIKE ?', "%#{params[:topic]}%")
    end

    if params[:sort].present? || params[:order].present?
      sort = params[:sort].presence || 'updated_at'
      if params[:order] == 'asc'
        scope = scope.order(Arel.sql(sort).asc.nulls_last)
      else
        scope = scope.order(Arel.sql(sort).desc.nulls_last)
      end
    else
      scope = scope.order(@sort = Arel.sql("(repository ->> 'stargazers_count')::text::integer").desc.nulls_last)
    end

    @pagy, @lists = pagy(scope)
  end

  def show
    @list = List.find(params[:id])
  end
end