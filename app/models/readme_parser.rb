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
    ['Contents', 'Contributors', 'Artwork and License']
  end

  def links(category, sub_category)
    @links ||= parse_links
    @links[category][sub_category]
  end

  def parse_links
    links = {}
    current_category = nil
    current_sub_category = nil

    @readme.each_line do |line|
      line.strip!
      if line.start_with?('## ')
        category = line[3..-1].strip
        if ignored_categories.include?(category)
          current_category = nil
        else
          current_category = category
          links[current_category] ||= {}
        end
      elsif current_category && line.start_with?('### ')
        current_sub_category = line[4..-1].strip
        links[current_category][current_sub_category] ||= []
      elsif current_category && line.include?('[') && line.include?('](')
        link_text_start = line.index('[') + 1
        link_text_end = line.index(']')
        link_text = line[link_text_start...link_text_end]
  
        link_url_start = line.index('](') + 2
        link_url_end = line.index(')', link_url_start)
        link_url = line[link_url_start...link_url_end]
  
        if link_url_end && line.index('-', link_url_end)
          description_start = line.index('-', link_url_end) + 1
          description = line[description_start..-1].strip
        else
          description = nil
        end

        links[current_category][current_sub_category] ||= []
        links[current_category][current_sub_category] << { name: link_text.strip, url: link_url.strip, description: description.strip }
      elsif line.start_with?('- ') && line.include?('[') && line.include?('](')
        link_text_start = line.index('[') + 1
        link_text_end = line.index(']')
        link_text = line[link_text_start...link_text_end]

        link_url_start = line.index('](') + 2
        link_url_end = line.index(')', link_url_start)
        link_url = line[link_url_start...link_url_end]

        if link_url_end && line.index('-', link_url_end)
          description_start = line.index('-', link_url_end) + 1
          description = line[description_start..-1].strip
        else
          description = nil
        end

        links['Uncategorized'] ||= {}
        links['Uncategorized']['Uncategorized'] ||= []
        links['Uncategorized']['Uncategorized'] << { name: link_text.strip, url: link_url.strip, description: description.strip }
      

      
      
      end
    end
  
    links
  end
end