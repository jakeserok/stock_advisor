api_key = Rails.application.credentials.dig(:finnhub, :api_key)

FinnhubRuby.configure do |config|
  config.api_key['api_key'] = api_key
end

@finnhub = FinnhubRuby::DefaultApi.new