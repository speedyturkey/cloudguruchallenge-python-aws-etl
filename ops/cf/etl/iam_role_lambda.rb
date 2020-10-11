resource :IamRoleLambdaFunction, 'AWS::IAM::Role' do
  path '/'
  assume_role_policy_document(
    Version: '2012-10-17',
    Statement: [
      {
        Effect: :Allow,
        Principal: {
          Service: 'lambda.amazonaws.com'
        },
        Action: 'sts:AssumeRole'
      }
    ]
  )
  policies [
    {
      PolicyName: :LambdaFunction,
      PolicyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: :Allow,
            Action: [
              'logs:CreateLogGroup',
              'logs:CreateLogStream',
              'logs:PutLogEvents'
            ],
            Resource: 'arn:aws:logs:*:*:*'
          },
        ]
      }
    },
    {
      PolicyName: :DynamoAccess,
      PolicyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: :Allow,
            Action: 'dynamodb:ListTables',
            Resource: '*'
          },
          {
            Effect: :Allow,
            Action: [
              'dynamodb:DescribeTable',
              'dynamodb:DeleteItem',
              'dynamodb:GetItem',
              'dynamodb:BatchGetItem',
              'dynamodb:BatchWriteItem',
              'dynamodb:PutItem',
              'dynamodb:Query',
              'dynamodb:UpdateItem',
              'dynamodb:UpdateTable',
            ],
            Resource: Fn.import_value(Fn.sub('${dynamo}-DynamoDbTableArn'))
          }
        ]
      }
    },
    {
      PolicyName: :SnsAccess,
      PolicyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: :Allow,
            Action: [
              'sns:Publish',
              'sns:GetTopicAttributes'
            ],
            Resource: Fn::ref(:SnsTopic)
          }
        ]
      }
    }
  ]
end
