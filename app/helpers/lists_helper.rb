module ListsHelper
  def list_description(description)
    html = Commonmarker.to_html(description, plugins: { syntax_highlighter: nil })
    sanitize(html, tags: %w[a code em strong del br], attributes: %w[href title])
  rescue Commonmarker::NestingDepthExceededError
    h(description)
  end

  def list_filter_path(changes)
    list_path(@list, @filters.merge(changes).compact.symbolize_keys.merge(anchor: 'list-entries'))
  end
end
