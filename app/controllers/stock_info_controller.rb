class StockInfoController < ApplicationController
  def index
    news = finnhub.market_news('general')
    @news = news[0..8]
  end

  def stocks
    @symbols = stock_symbols
  end

  def stock
    stock = params['symbol']
    @info = finnhub.symbol_search(stock).result.select { |record| record.symbol == stock }.first
    @advisor = FinanceAiAdvisor.new(stock)
    @trends = @advisor.trends
    @reddit_score = @advisor.reddit_score
    @twitter_score = @advisor.twitter_score
    @daily_price_diff = @advisor.daily_price_diff
    @weekly_price_diff = @advisor.weekly_price_diff
    @monthly_price_diff = @advisor.monthly_price_diff
    ai_stock = AiResponse.find_by(stock: stock)
    if ai_stock && Date.parse(ai_stock.created_at.to_s) == Date.today
      @message = ai_stock.response
    else
      ai = AiResponse.new(stock: stock)
      ai.response = @advisor.get_opinion.dig('choices', 0, 'message', 'content')
      ai.save!
      @message = ai.response
    end
  end

  private

  def finnhub
    @finnhub ||= FinnhubRuby::DefaultApi.new
  end

  def stock_symbols
    @stocks = YAML.load_file('config/stocks.yml')['symbols']
  end
  
  def current_time
    DateTime.now.to_time.to_i
  end

  def previous_day_time
    (DateTime.now - 1.days).to_time.to_i
  end

  def previous_week_time
    (DateTime.now - 7.days).to_time.to_i
  end

  def previous_month_time
    (DateTime.now - 1.months).to_time.to_i
  end
end
