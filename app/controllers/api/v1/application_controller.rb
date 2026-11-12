class Api::V1::ApplicationController < ApplicationController
  after_action { pagy_headers_merge(@pagy) if @pagy }

  def set_cache_headers
    return unless request.get? || request.head?
    expires_in 5.minutes, public: true, stale_while_revalidate: 30.minutes
    response.headers['CDN-Cache-Control'] = "max-age=#{1.hour.to_i}, stale-while-revalidate=#{4.hours.to_i}"
  end

  private

  # Slugs contain slashes and may be sent unencoded, so a slug whose last
  # segment is a nested route name (owner/projects, host/owner/lists) is routed
  # to that nested action with the rest of the slug as its parent. Returns the
  # record the whole path names when the parent doesn't exist.
  def misrouted_record(model, parent, nested_route)
    return if find_by_id_or_slug(model, parent)

    model.find_by_slug("#{parent}/#{nested_route}")
  end

  def find_by_id_or_slug(model, param)
    if param.to_i.to_s == param
      model.find_by(id: param)
    else
      model.find_by_slug(param)
    end
  end

  def render_list(list)
    @list = list
    render 'api/v1/lists/show' if stale?(@list, public: true)
  end

  def render_project(project)
    raise ActiveRecord::RecordNotFound if project.has_blocked_topic?
    raise ActiveRecord::RecordNotFound if project.owner_hidden?

    @project = project
    render 'api/v1/projects/show' if stale?(@project, public: true)
  end
end
