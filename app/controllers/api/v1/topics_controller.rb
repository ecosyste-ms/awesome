class Api::V1::TopicsController < Api::V1::ApplicationController
  def index
    scope = Topic.order(github_count: :desc)

    scope = scope.search(params[:query]) if params[:query].present?

    @pagy, @topics = pagy(scope)
  end

  def show
    @topic = Topic.find_by!(slug: params[:id])
  end

end