code = File.read(File.join(File.dirname(__FILE__), 'handler.py'))

resource :EtlLambdaFunction, 'AWS::Lambda::Function', DependsOn: :IamRoleLambdaFunction do
  handler 'index.main'
  role Fn::get_att(:IamRoleLambdaFunction, :Arn)
  code(
    ZipFile: code
  )
  runtime 'python3.7'
  self["Properties"]["Timeout"] = 60
  environment do
    variables(
      DYNAMO_DB_TABLE_NAME: Fn.import_value(Fn.sub('${dynamo}-DynamoDbTableName')),
      SNS_TOPIC_ARN: Fn.ref(:SnsTopic)
    )
  end
end
