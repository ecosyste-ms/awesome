class ListsController < ApplicationController
  before_action :sanitize_params, only: [:index, :show]

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
      sort = sanitize_sort(List.sortable_columns)
      if params[:order] == 'asc'
        scope = scope.order(sort.asc.nulls_last)
      else
        scope = scope.order(sort.desc.nulls_last)
      end
    else
      scope = scope.order_by_stars
    end

    respond_to do |format|
      format.html do
        @pagy, @lists = pagy_countless(scope)
        fresh_when(@lists, public: true)
      end
      format.rss do
        scope = scope.reorder(created_at: :desc)
        @pagy, @lists = pagy(scope, items: 100)
        fresh_when(@lists, public: true)
        render layout: false
      end
    end
  end

  def show
    if params[:id].to_i.to_s == params[:id]
      @list = List.find(params[:id])
      redirect_to list_path(@list, params.permit(:page, :language, :topic, :category, :sub_category)), status: :moved_permanently and return
    else
      @list = List.find_by_slug!(params[:id])
      raise ActiveRecord::RecordNotFound unless @list.displayable?
      @filters = params.permit(:language, :topic, :category, :sub_category).to_h.reject { |_, value| value.blank? }
      scope = @list.filtered_list_projects(@filters).includes(:project).order(:category, :sub_category, :id)
      @pagy, @list_projects = pagy_countless(scope, limit: 200)
      fresh_when(etag: [@list, @filters, @pagy.page, @list_projects, @list_projects.map(&:project)], public: true)
    end
  end

  def markdown
    @list_of_lists = List.displayable.where(list_of_lists: true).sort_by(&:markdown_sort_key)
    @other_lists = List.displayable.where(list_of_lists: false).sort_by(&:markdown_sort_key)
    @languages = @other_lists.map(&:primary_language).reject(&:blank?).uniq.sort_by(&:downcase)
    @topic_lists = List.markdown_topic_groups(@other_lists.select { |list| list.primary_language.blank? })
    @uncategorized_lists = @topic_lists.delete(nil)&.fetch(:lists) || []
    if stale?(etag: [@list_of_lists, @other_lists, @topic_lists.transform_values { |group| group[:name] }], public: true)
      render layout: false, content_type: 'text/plain'
    end
  end

  private

  def sanitize_params
    [:query, :sort, :order, :topic, :language, :category, :sub_category].each do |param|
      params[param] = params[param].delete("\x00") if params[param].present?
    end
  end
end
