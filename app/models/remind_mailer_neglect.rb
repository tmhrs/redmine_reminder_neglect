class RemindMailerNeglect < Mailer
  def self.reminders_neglect(options={})
    days = options[:days] || 7
    project = options[:project] ? Project.find(options[:project]) : nil
    tracker = options[:tracker] ? Tracker.find(options[:tracker]) : nil
    user_ids = options[:users]

    day_from = (-days).day.from_now.to_date
    scope = Issue.open.where("#{Issue.table_name}.assigned_to_id IS NOT NULL" +
      " AND #{Project.table_name}.status = #{Project::STATUS_ACTIVE}" +
      " AND #{User.table_name}.type != 'AnonymousUser'" +
      " AND #{Issue.table_name}.updated_on <= ?", day_from
    )
    scope = scope.where(:assigned_to_id => user_ids) if user_ids.present?
    scope = scope.where(:project_id => project.id) if project
    scope = scope.where(:tracker_id => tracker.id) if tracker

    issues_by_assignee = scope.includes(:status, :assigned_to, :project, :tracker).all.group_by(&:assigned_to)
    issues_by_assignee.keys.each do |assignee|
      if assignee.is_a?(Group)
        assignee.users.each do |user|
          issues_by_assignee[user] ||= []
          issues_by_assignee[user] += issues_by_assignee[assignee]
        end
      end
    end

    issues_by_assignee.each do |assignee, issues|
      reminder_neglect(assignee, issues, days, project, tracker, day_from).deliver if assignee.is_a?(User) && assignee.active?
    end
  end

  def reminder_neglect(user, issues, days, project, tracker, day_from)
    set_language_if_valid user.language
    @issues = issues
    @days = days
    @issues_url = url_for(:controller => 'issues', :action => 'index',
                          :set_filter => 1, :assigned_to_id => user.id,
                          :project_id => (project ? project.id : nil),
                          :tracker_id => (tracker ? tracker.id : nil),
                          :updated_on => "<=" + day_from.strftime("%Y-%m-%d"),
                          :sort => 'updated_on:asc')
    mail :to => user.mail,
      :subject => l(:mail_subject_reminder_neglect, :count => issues.size, :days => days)
  end
end
