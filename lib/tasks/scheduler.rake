desc 'automated questioning'

task ai_opinion_generator: :environment do
  YAML.load_file('config/stocks.yml')['symbols'].each_with_index do |s, i|
    GetAiOpinionJob.perform_in((i * 20).seconds, s)
  end
  puts "AI Opinions generated at #{DateTime.now}"
end