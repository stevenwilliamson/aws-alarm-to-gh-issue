require 'ostruct'
class Configuration < OpenStruct
  def initialize()
    super
    super.aws_account_name = "foo"
  end
end

test = Configuration.new
puts test.aws_account_name
