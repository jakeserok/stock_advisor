class FinanceAiAdvisor
  attr_reader :stock

  def initialize(stock)
    @stock = stock
  end

  def openai_client
    @openai_client ||= OpenAI::Client.new
  end

  def finnhub
    @finnhub ||= FinnhubRuby::DefaultApi.new
  end

  def sentiment(stock = self.stock)
    @sentiment ||= finnhub.social_sentiment(stock)
  end

  def trends(stock = self.stock)
    @trends ||= finnhub.recommendation_trends(stock)
  end

  def reddit_score(stock = self.stock)
    score = 0
    reddit_sentiment = sentiment.to_hash[:reddit]
    unless reddit_sentiment.blank?
      reddit_sentiment.each do |r|
        score += r[:score]
      end
      score / @sentiment.to_hash[:reddit]&.count
    else
      score
    end
  end

  def twitter_score(stock = self.stock)
    score = 0
    twitter_sentiment = sentiment.to_hash[:twitter]
    unless twitter_sentiment.blank?
      twitter_sentiment.each do |t|
        score += t[:score]
      end
      score / @sentiment.to_hash[:twitter].count
    else
      score
    end
  end

  def daily_price_diff
    @daily_prince_diff ||= finnhub.stock_candles(stock, 'D', previous_day_time, current_time)
  end

  def weekly_price_diff
    @weekly_price_diff ||= finnhub.stock_candles(stock, 'W', previous_week_time, current_time)
  end

  def monthly_price_diff
    @month_price_diff ||= finnhub.stock_candles(stock, 'M', previous_month_time, current_time)
  end

  def prompts
    @prompts ||= YAML.load_file('config/prompts.yml')['ai_prompts']
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

  def scoring_message(stock = self.stock)
    prompt_array = []
    prompt_array << prompts['setup']
    prompt_array << "The social sentiment of #{stock} has a score of #{reddit_score} on reddit. 
    There are a total of #{sentiment.reddit.count} mentions on reddit.
    The social sentiment of #{stock} has a score of #{twitter_score} on twitter. 
    There are a total of #{sentiment.twitter.count} mentions on twitter.
    A score of 1 is good and a score of -1 is bad, 
    therefore a score of 0 would be considered average and anything higher could be precevied as good. 
    The opposite can be said for anything below 0."
    prompt_array << "The market professionals say the following for this month: #{trends.first}."
    prompt_array << "Price data is as follows: 
    Yesterday's Opening price: #{Time.at(daily_price_diff.t.first).strftime('%m/%d/%y')}: $#{daily_price_diff.o.first} and 
    Today's Opening price: #{Time.at(daily_price_diff.t.last).strftime('%m/%d/%y')}: $#{daily_price_diff.o.last}. 
    Last Week's Opening price: #{Time.at(weekly_price_diff.t.first).strftime('%m/%d/%y')}: $#{weekly_price_diff.o.first} and 
    This Week's Opening price: #{Time.at(weekly_price_diff.t.last).strftime('%m/%d/%y')}: $#{weekly_price_diff.o.last}. 
    Last Month's Opening price: #{Time.at(monthly_price_diff.t.first).strftime('%m/%d/%y')}: $#{monthly_price_diff.o.first} and 
    This Month's Opening price: #{Time.at(monthly_price_diff.t.last).strftime('%m/%d/%y')}: $#{monthly_price_diff.o.last}."
    prompt_array << prompts['closing']
    prompt_array.join(' ')
  end

  def get_opinion
    openai_client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [{ role: "user", content: scoring_message }]
      }
    )
  end
end
