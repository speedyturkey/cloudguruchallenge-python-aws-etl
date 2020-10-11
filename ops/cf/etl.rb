description 'ETL Lambda + Event Rule + Notification'

parameter :app, type: :String
parameter :branch, type: :String
parameter :dynamo, type: :String
parameter :email, type: :String, default: "speedyturkey@gmail.com"

include_template(
  'etl/event_rule.rb',
  'etl/iam_role_lambda.rb',
  'etl/lambda.rb',
  'etl/sns.rb',
)
