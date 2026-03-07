SecureHeaders::Configuration.default do |config|
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self' 'unsafe-inline' https://cdnjs.cloudflare.com https://media.ethicalads.io https://server.ethicalads.io),
    style_src: %w('self' 'unsafe-inline' https://fonts.googleapis.com),
    font_src: %w('self' https://fonts.gstatic.com),
    img_src: %w('self' data: https:),
    connect_src: %w('self' *.ecosyste.ms https://server.ethicalads.io)
  }
end
