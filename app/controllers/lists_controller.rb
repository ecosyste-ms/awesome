class ListsController < ApplicationController
  def index
    scope = List.displayable

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
      scope = scope.order(@sort = Arel.sql("(repository ->> 'stargazers_count')::text::integer").desc.nulls_last)
    end

    @pagy, @lists = pagy(scope)
  end

  def show
    @list = List.find(params[:id])
  end

  def markdown
    @list_of_lists = List.displayable.where(list_of_lists: true).order(Arel.sql("(repository ->> 'stargazers_count')::text::integer").desc.nulls_last, 'url asc').all.select{|l| l.description.present? && !l.name.include?('?') && !l.topics.include?('starred') }
    @other_lists = List.displayable.where(list_of_lists: false).order(Arel.sql("(repository ->> 'stargazers_count')::text::integer").desc.nulls_last, 'url asc').all.select{|l| l.description.present? && !l.name.include?('?') && !l.topics.include?('starred') }
    render layout: false, content_type: 'text/plain'
  end
end