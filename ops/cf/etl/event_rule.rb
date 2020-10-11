resource :DailyEtlRule, 'AWS::Events::Rule' do
  schedule_expression 'cron(0 0 * * ? *)'
  state :ENABLED
  targets [
    {
      Id: Fn::ref('AWS::StackName'),
      Arn: Fn::get_att(:EtlLambdaFunction, :Arn),
    }
  ]
end
