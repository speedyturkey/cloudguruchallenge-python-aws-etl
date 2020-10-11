description 'DynamoDB backend'

parameter :app, type: :String
parameter :branch, type: :String

include_template(
  'dynamo/table.rb',
)
