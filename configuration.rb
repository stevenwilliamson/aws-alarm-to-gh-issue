class Configuration 
  attr_accessor :aws_account_name, :github_repo, :alarm_label, :issue_assignee,
  :enable_alarm_tags

  def initialize()
    @aws_account_name = ENV['AWS_ACCOUNT_NAME'] || 'Unknown account'
    @github_repo = ENV['GITHUB_REPO'] || ""
    @alarm_label = ENV['ALARM_LABEL'] || "alarm"
    @issue_assignee = ENV['ISSUE_ASSIGNEE'] || nil
    @enable_alarm_tags = ENV['ENABLE_ALARM_TAGS'] || false
    print_config()
  end
  
  def print_config
    puts("Current configuration:")
    puts("aws_account_name: #{@aws_account_name}")
    puts("github_repo: #{@github_repo}")
    puts("alarm_label: #{@alarm_label}")
    puts("issue_assignee: #{@issue_assignee}")
  end
end