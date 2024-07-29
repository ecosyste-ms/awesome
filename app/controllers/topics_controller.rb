class TopicsController < ApplicationController
  def index
    scope = Topic.where('github_count > 0').order(github_count: :desc)

    scope = scope.search(params[:query]) if params[:query].present?

    @pagy, @topics = pagy(scope)
  end

  def show
    @topic = Topic.find_by!(slug: params[:id])
    scope = @topic.projects.order_by_stars
    @pagy, @projects = pagy_countless(scope)
  end
end
