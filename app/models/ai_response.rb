class AiResponse < ApplicationRecord
  validates_presence_of :stock

  def self.search(stock)
    stock = self.find_by(stock: stock)
    stock_symbols = YAML.load_file('config/stocks.yml')['symbols']
    return if stock_symbols.include?(stock)

    trends = FinanceAiAdvisor.new(stock).trends
    return if trends.blank?

    temp = stock_symbols
    temp['symbols'] << stock
    File.open('config/stocks.yml', 'w') { |file| file.write(temp.to_yaml) }
    stock
  end
end
