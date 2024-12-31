xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.rss version: '2.0' do
  xml.channel do
    xml.title 'Awesome Lists RSS Feed'
    xml.link lists_url
    xml.description 'Latest awesome lists'
    xml.language 'en-us'
    xml.pubDate Time.current.rfc822

    @lists.each do |list|
      xml.item do
        xml.title list.to_s
        xml.description list.description || 'No description available'
        xml.link list_url(list)
        xml.pubDate list.updated_at.rfc822
        xml.guid list_url(list), isPermaLink: true
      end
    end
  end
end