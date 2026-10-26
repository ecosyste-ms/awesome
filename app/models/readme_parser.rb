class ReadmeParser

  def self.load(url)
    conn = Faraday.new(url: url) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    response = conn.get
    return unless response.success?
    markdown = response.body
    new(markdown)
  end

  attr_reader :readme

  def initialize(readme)
    @readme = readme
  end

  def ignored_categories
    ['contents', 'table of contents', 'contributors', 'artwork and license', 'license', 'licenses', 'list of licenses']
  end

  def links(category, sub_category)
    @links ||= parse_links
    @links[category][sub_category]
  end

  def parse_links
    links = {}
    current_category = nil
    current_sub_category = nil
    ignored = false

    Commonmarker.parse(readme).walk do |node|
      if node.type == :heading && node.header_level == 2
        current_category = plain_text(node)
        current_sub_category = nil
        ignored = ignored_categories.include?(current_category.downcase)
      elsif node.type == :heading && node.header_level == 3
        current_sub_category = plain_text(node)
      elsif !ignored
        entry = if node.type == :table_row && node.previous_sibling
          table_entry(node)
        elsif node.type == :paragraph && node.parent.type == :item && node.previous_sibling.nil?
          list_entry(node)
        end
        next unless entry

        category = current_category || 'Uncategorized'
        sub_category = current_category ? current_sub_category : 'Uncategorized'
        links[category] ||= {}
        links[category][sub_category] ||= []
        links[category][sub_category] << entry
      end
    end

    links
  end

  def entry_link(node)
    node.walk.find { |child| child.type == :link && child.walk.none? { |descendant| descendant.type == :image } && plain_text(child).present? }
  end

  def plain_text(node)
    node.walk.filter_map { |child| child.string_content if [:text, :code].include?(child.type) }.join.strip
  end

  def inline_markdown(nodes)
    nodes.map { |node| node.to_commonmark(plugins: { syntax_highlighter: nil }).delete_suffix("\n") }.join.strip
  end

  def list_entry(node)
    children = node.to_a
    index = children.index { |child| entry_link(child) }
    return unless index

    link = entry_link(children[index])
    description = inline_markdown(children.drop(index + 1)).sub(/\A[-–—:]\s+/, '')
    { name: plain_text(link), url: link.url, description: description.presence }
  end

  def table_entry(node)
    cells = node.to_a
    link = entry_link(cells.first)
    return unless link

    headers = node.parent.first_child.map { |cell| plain_text(cell).downcase }
    description_cell = cells[headers.index('description') || 1]
    description = inline_markdown(description_cell.to_a) if description_cell
    { name: plain_text(link), url: link.url, description: description.presence }
  end
end
