class ListsController < ApplicationController
  def index
    scope = List.displayable

    if params[:topic].present?
      scope = scope.topic(params[:topic])
    end

    if params[:language].present?
      scope = scope.primary_language(params[:language])
    end

    if params[:query].present?
      scope = scope.search(params[:query])
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
    fresh_when(@lists, public: true)
  end

  def show
    if params[:id].to_i.to_s == params[:id]
      @list = List.find(params[:id])
      redirect_to @list, status: :moved_permanently
    else
      @list = List.find_by_slug!(params[:id])
      fresh_when(@list, public: true)
    end
  end

  def markdown
    @list_of_lists = List.displayable.where(list_of_lists: true).order(Arel.sql("(repository ->> 'stargazers_count')::text::integer").desc.nulls_last, 'url asc').all
    @other_lists = List.displayable.where(list_of_lists: false).order(Arel.sql("(repository ->> 'stargazers_count')::text::integer").desc.nulls_last, 'url asc').all
    render layout: false, content_type: 'text/plain'
  end
end