class TopicsController < ApplicationController
  def index
    scope = Topic.where('github_count > 99').order(github_count: :desc)

    scope = scope.search(params[:query]) if params[:query].present?

    @pagy, @topics = pagy(scope)
  end

  def suggestions
    scope = Topic.where('github_count > 99').order(github_count: :desc).not_language.with_wikipedia.with_logo.not_google.other_excluded
    @pagy, @topics = pagy(scope)
  end

  def show
    @topic = Topic.find_by!(slug: params[:id])
    scope = @topic.projects.order_by_stars.not_awesome_list
    @lists = @topic.lists.limit(50).order_by_stars.displayable
    @pagy, @projects = pagy_countless(scope)
  end
end
