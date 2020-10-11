resource :SnsTopic, 'AWS::SNS::Topic'

resource :SnsSubscription, 'AWS::SNS::Subscription' do
  Protocol :email
  Endpoint Fn.ref(:email)
  TopicArn Fn.ref(:SnsTopic)
end
