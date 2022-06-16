# Handles basic formatting of an AWS Alarm state change event
# for GitHub
class GitHubAlarmFormatter
    def initialize(alarm, aws_account_name:)
      @alarm = alarm
      @aws_account_name = aws_account_name
    end
    
    def title()
      title = "🚨 AWS Account #{@aws_account_name}: "
      title += "Alarm " + @alarm['detail']['alarmName'] + " is in Alarm"
    end
    
    def state()
      @alarm['detail']['state']['value']
    end
    
    def issue_description()
      desc = ""
      if state() == "ALARM"
        desc = <<~DESC
        ### ❌AWS Alarm #{@alarm['detail']['alarmName']} entered alarm state at #{@alarm['detail']['state']['timestamp']}
      
        Alarm Description: #{@alarm['detail']['configuration']['description']}
      
        The reason for this alarm entering alarm state is:
        #{@alarm['detail']['state']['reason']}
        
        ![screen-gif](https://media.giphy.com/media/nrXif9YExO9EI/giphy.gif)
        DESC
      elsif state() == "OK"
        desc = <<~DESC
        ### ✅Alarm has been resolved and reverted back to an OK state.
        Reason: #{@alarm['detail']['state']['reason']}
        
        ![gif](https://media.giphy.com/media/EDt1m8p5hqXG8/giphy.gif)
        DESC
      end
      return desc
    end
  end