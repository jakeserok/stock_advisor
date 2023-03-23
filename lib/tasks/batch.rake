namespace :batch do
  desc "Get Ai opinion on various stocks"
  task ai_opinion_generator: :environment do
    GetAiOpinionJob.perform_now
    puts "AI Opinions generated at #{DateTime.now}"
  end

end
