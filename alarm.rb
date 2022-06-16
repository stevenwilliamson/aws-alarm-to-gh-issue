require 'octokit'
require 'json'
require 'aws-sdk-cloudwatch'
require 'configuration.rb'
require 'github_alarm_formatter.rb'
require 'github_alarm_handler.rb'

def alarm?(event)
  event['detail-type'] == "CloudWatch Alarm State Change"
end

def handle(event:, context:)
  if alarm?(event)
    $config ||= Configuration.new()
    puts("Handling Alarm id: #{event["id"]}")
    gh = GitHubAlarmHandler.new(aws_account_name: $config.aws_account_name, github_repo: $config.github_repo)
    gh.handle_alarm(event: event)
  else
    puts("Event recivied but does not look like an alarm, ignoring")
    puts(event.inspect)
  end
end
