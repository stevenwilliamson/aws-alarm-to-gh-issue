# Class that abstracts away dealing with GitHub
class GitHubAlarmHandler
  def initialize(aws_account_name:, github_repo:)
    @aws_account_name = aws_account_name
    @default_github_repo = github_repo
  end

  def handle_alarm(event:)
    # Skip alarms that looks like target tracking alarms for scaling policies
    # These just generate noise
    if target_tracking_alarm?(event)
      puts('Target Tracking alarm looks like an alarm for a scaling policy skipping...')
      return { statusCode: 200 }.to_json
    end

    alarm = GitHubAlarmFormatter.new(event, aws_account_name: @aws_account_name)
    if $config.enable_alarm_tags
      client = Aws::CloudWatch::Client.new
      alarm_arn = event['resources'].first
      tags = aws_tags_to_hash(client.list_tags_for_resource(resource_arn: alarm_arn))
      if tags.has_key?('github-repo')
        github_repo = tags['github-repo']
        puts("Alarm has tag configuration, setting github repo to #{github_repo}")
      else
        github_repo = @default_github_repo
      end
    end

    create_or_update_alarm(alarm, github_repo)

    # Let Lambda know we handled the event OK
    { statusCode: 200 }.to_json
  end

  def create_or_update_alarm(alarm, github_repo)
    if alarm.state == 'ALARM'
      if issue = existing_issue(alarm.title)
        renew_alarm(issue: issue,
                    repo: github_repo,
                    desc: alarm.issue_description)
      else
        create_issue(repo: github_repo,
                     title: alarm.title,
                     desc: alarm.issue_description,
                     labels: [$config.alarm_label],
                     assignee: $config.issue_assignee)
      end
    elsif alarm.state == 'OK'
      if issue = existing_issue(alarm.title)
        mark_alarm_ok(issue: issue,
                      repo: github_repo,
                      desc: alarm.issue_description)
      end
    end
  end

  def create_issue(repo:, title:, desc:, labels:, assignee:)
    client.create_issue(repo, title, desc, labels: labels, assignee: assignee)
  end

  def renew_alarm(issue:, repo:, desc:)
    existing_label_names = issue.labels.map { |l| l['name'] }

    puts("Issue has existing lables #{existing_label_names}")

    if issue.state == 'open' && existing_label_names.include?(label_for_in_alarm_state)
      puts('GitHub issue open and still shows alarm is in alarm state, skipping update')
      return
    end

    puts "renewing alarm for #{repo} issue #{issue.number}"

    new_label_names = [existing_label_names, $config.alarm_label, label_for_in_alarm_state].flatten
    new_label_names.delete(label_for_in_ok_state)
    client.add_comment(repo, issue.number, desc)

    puts("Assining labels #{new_label_names.inspect}")
    client.update_issue(
      repo,
      issue.number,
      state: 'open',
      labels: new_label_names
    )
  end

  def mark_alarm_ok(issue:, repo:, desc:)
    label_names = issue.labels.map { |l| l['name'] }
    if issue.state == 'open'
      puts("Issue has existing labels #{label_names}, updating labels to show alarm in OK sta")
      label_names.delete(label_for_in_alarm_state)
      label_names << label_for_in_ok_state
      client.update_issue(repo, issue.number, labels: label_names)
      client.add_comment(repo, issue.number, desc)
    end
  end

  def label_for_in_alarm_state
    "#{$config.alarm_label}:state:ALARM"
  end

  def label_for_in_ok_state
    "#{$config.alarm_label}:state:OK"
  end

  def get_alarm_tags(alarm_arn)
    cw_client = Aws::CloudWatch::Client.new
    cw_client.list_tags_for_resource(resource_arn: alarm_arn)
  end

  # Finds an issue with the same title and returns it's issue number
  # else nil if no matches
  def existing_issue(issue_title)
    issues = client.issues @github_repo, labels: $config.alarm_label, state: 'all'
    matched_issues = issues.select { |i| i.title == issue_title }
    if matched_issues.length > 0
      puts("Found ISSUE NO: #{matched_issues.first.number}")
      matched_issues.first
    end
  end

  def client
    $client ||= Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'])
  end

  def aws_tags_to_hash(tags)
    tags[:tags].to_h { |item| [item[:key], item[:value]] }
  end

  def target_tracking_alarm?(event)
    event['detail']['alarmName'] =~ /^TargetTracking-/
  end
end
