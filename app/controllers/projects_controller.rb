class ProjectsController < ApplicationController
  def show
    if params[:id].to_i.to_s == params[:id]
      @project = Project.find(params[:id])
      redirect_to @project, status: :moved_permanently
    else
      @project = Project.find_by_slug!(params[:id])
      raise ActiveRecord::RecordNotFound if @project.owner_hidden?
      fresh_when(@project, public: true)
    end
  end

  def index
    @scope = Project.not_awesome_list.where.not(last_synced_at: nil).with_repository.visible_owners

    if params[:keyword].present?
      @scope = @scope.keyword(params[:keyword])
    end

    if params[:owner].present?
      owner_record = Owner.find_by(name: params[:owner].downcase)
      raise ActiveRecord::RecordNotFound if owner_record&.hidden?
      @scope = @scope.owner(params[:owner])
    end

    if params[:language].present?
      @scope = @scope.language(params[:language])
    end

    if params[:sort].present? || params[:order].present?
      sort = params[:sort].presence || 'updated_at'
      if params[:order] == 'asc'
        @scope = @scope.order(Arel.sql(sort).asc.nulls_last)
      else
        @scope = @scope.order(Arel.sql(sort).desc.nulls_last)
      end
    else
      @scope = @scope.order_by_stars
    end

    @pagy, @projects = pagy_countless(@scope)
    raise ActiveRecord::RecordNotFound if @projects.empty?
    fresh_when(@projects, public: true)
  end

  def lookup
    @project = Project.find_by(url: params[:url].downcase)
    if @project.nil?
      @project = Project.create(url: params[:url].downcase)
      @project.sync_async
    end
    fresh_when @project, public: true
    redirect_to @project
  end
end