namespace :sample do
  desc "Sample Test"
  task test: :environment do
    puts 'hi cron'
  end

end
