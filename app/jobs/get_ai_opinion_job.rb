class GetAiOpinionJob < ApplicationJob
  queue_as :urgent

  NO_OPINION = 'No opinion on this stock currently. Please try again later.'.freeze

  def perform(*args)
    stocks.each do |stock|
      stock_array = [AiResponse.find_by(stock: stock)].flatten
      current_stock = nil
      stock_array.compact.present? ? current_stock = stock_array.max { :created_at } : current_stock = AiResponse.new(stock: stock)
      return unless current_stock

      current_stock_date = current_stock.created_at.iso8601.split('T').first
      if current_stock_date.nil? || current_stock_date != Date.today.iso8601 || current_stock&.response == NO_OPINION
        ai_opinion = FinanceAiAdvisor.new(stock: stock).get_opinion
        unless ai_opinion['error']
          current_stock.response = ai_opinion.dig('choices', 0, 'message', 'content')
        else
          current_stock.response = NO_OPINION
        end
        current_stock.save!
      end
    end
  end

  private

  def stocks
    @stocks = YAML.load_file('config/stocks.yml')['symbols']
  end
end
