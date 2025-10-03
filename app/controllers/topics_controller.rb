class TopicsController < ApplicationController
  def index
    scope = Topic.where('github_count > 99').order(github_count: :desc)

    scope = scope.search(params[:query]) if params[:query].present?

    @pagy, @topics = pagy(scope)
    fresh_when(@topics, public: true)
  end

  def suggestions
    scope = Topic.where('github_count > 99').order(github_count: :desc).not_language.suggestable.not_google.other_excluded.with_github_url
    @pagy, @topics = pagy(scope)
    fresh_when(@topics, public: true)
  end

  def show
    @topic = Topic.find_by!(slug: params[:id])
    scope = @topic.projects.order_by_stars.not_awesome_list
    @lists = @topic.lists.limit(50).order_by_stars.displayable
    @pagy, @projects = pagy_countless(scope)
    fresh_when(@projects, public: true)
  end
end
