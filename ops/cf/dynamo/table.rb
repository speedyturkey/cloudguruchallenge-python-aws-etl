resource :DynamoDbTable, 'AWS::DynamoDB::Table' do
  table_name Fn::sub('${app}-${branch}-covid-data')
  attribute_definitions [
    { AttributeName: :date, AttributeType: :S },
  ]
  key_schema [
    { AttributeName: :date, KeyType: :HASH },
  ]
  billing_mode :PAY_PER_REQUEST
end

output :DynamoDbTableArn, Fn.get_att(:DynamoDbTable, :Arn), export: Fn::sub('${AWS::StackName}-DynamoDbTableArn')
output :DynamoDbTableName, Fn.ref(:DynamoDbTable), export: Fn::sub('${AWS::StackName}-DynamoDbTableName')
