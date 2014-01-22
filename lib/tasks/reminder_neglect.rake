desc <<-END_DESC
Send reminders about issues due in the next days.

Available options:
  * days     => number of days to remind about (defaults to 7)
  * tracker  => id of tracker (defaults to all trackers)
  * project  => id or identifier of project (defaults to all projects)
  * users    => comma separated list of user/group ids who should be reminded

Example:
  rake redmine:send_reminders_neglect days=7 users="1,23, 56" RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :send_reminders_neglect => :environment do
    options = {}
    options[:days] = ENV['days'].to_i if ENV['days']
    options[:project] = ENV['project'] if ENV['project']
    options[:tracker] = ENV['tracker'].to_i if ENV['tracker']
    options[:users] = (ENV['users'] || '').split(',').each(&:strip!)

    Mailer.with_synched_deliveries do
      RemindMailerNeglect.reminders_neglect(options)
    end
  end
end
