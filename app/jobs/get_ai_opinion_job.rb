class GetAiOpinionJob
  include Sidekiq::Job
  attr_reader :stock

  NO_OPINION = 'No opinion on this stock currently. Please try again later.'.freeze

  def perform(stock)
    stock_array = [AiResponse.find_by(stock: stock)].flatten
    current_stock = nil
    stock_array.compact.present? ? current_stock = stock_array.max { :created_at } : current_stock = AiResponse.create!(stock: stock)
    return unless current_stock

    current_stock_date = current_stock.created_at&.iso8601.split('T').first || DateTime.now - 1.minutes
    if current_stock_date.nil? || current_stock_date != Date.today.iso8601 || current_stock&.response == NO_OPINION
      generated_opinion = ai_opinion(stock)
      unless generated_opinion['error']
        current_stock.response = generated_opinion.dig('choices', 0, 'message', 'content')
      else
        current_stock.response = NO_OPINION
      end
      p current_stock.response
      current_stock.save!
    end
  end

  private

  def ai_opinion(stock)
    @ai_opinion ||= FinanceAiAdvisor.new(stock).get_opinion
  end
end
