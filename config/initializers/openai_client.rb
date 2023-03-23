api_key = Rails.application.credentials.dig(:openai, :api_key)

OpenAI.configure do |config|
  config.access_token = api_key
end
