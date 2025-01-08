class Api::V1::ProjectsController < Api::V1::ApplicationController
  def index
    if params[:list_id].present?
      if params[:list_id].to_i.to_s == params[:list_id]
        @list = List.find(params[:list_id])
        redirect_to api_v1_list_projects_url(@list), status: :moved_permanently
      else
        @list = List.find_by_slug!(params[:list_id])
      end
      @projects = @list.projects.where.not(last_synced_at: nil)
    else
      @projects = Project.all.where.not(last_synced_at: nil)
    end

    if params[:keyword].present?
      @projects = @projects.keyword(params[:keyword])
    end

    @projects = @projects.includes(:list_projects)
    
    @pagy, @projects = pagy_countless(@projects)
    fresh_when(@projects, public: true)
  end

  def show
    if params[:id].to_i.to_s == params[:id]
      @project = Project.find(params[:id])
      redirect_to @project, status: :moved_permanently
    else
      @project = Project.find_by_slug!(params[:id])
      fresh_when(@project, public: true)
    end
  end

  def lookup
    raise ActionController::BadRequest.new('URL is required') unless params[:url].present?
    @project = Project.find_by(url: params[:url].downcase)
    if @project.nil?
      begin
        @project = Project.create(url: params[:url].downcase)
        @project.sync_async
      rescue ActiveRecord::RecordNotUnique
        @project = Project.find_by(url: params[:url].downcase)
      end
    end
    raise ActionController::NotFound.new('Project not found') if @project.nil?
    @project.sync_async if @project.last_synced_at.nil? || @project.last_synced_at < 1.day.ago
    fresh_when(@project, public: true)
  end

  def ping
    @project = Project.find(params[:id])
    @project.sync_async
    render json: { message: 'pong' }
  end

  def packages
    @projects = Project.reviewed.active.select{|p| p.packages.present? }.sort_by{|p| p.packages.sum{|p| p['downloads'] || 0 } }.reverse
  end

  def images
    @projects = Project.reviewed.with_readme.select{|p| p.readme_image_urls.present? }
  end
end