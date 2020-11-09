"""
  Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

from cfnlint.rules import CloudFormationLintRule
from cfnlint.rules import RuleMatch


class AMSResourceSupported(CloudFormationLintRule):
    """Check Base Resource Configuration"""

    id = "E3095"
    shortdesc = "Verify that resources are supported by AMS"
    description = "Verify that resources are supported by AMS"
    source_url = "https://aws.amazon.com/managed-services/features"
    tags = ["resources", "support", "AMS"]

    def match(self, cfn):
        """Check CloudFormation Resources"""

        matches = []

        valid_resource_types = (
            "AWS::ApiGateway::Account",
            "AWS::ApiGateway::ApiKey",
            "AWS::ApiGateway::Authorizer",
            "AWS::ApiGateway::BasePathMapping",
            "AWS::ApiGateway::ClientCertificate",
            "AWS::ApiGateway::Deployment",
            "AWS::ApiGateway::DocumentationPart",
            "AWS::ApiGateway::DocumentationVersion",
            "AWS::ApiGateway::DomainName",
            "AWS::ApiGateway::GatewayResponse",
            "AWS::ApiGateway::Method",
            "AWS::ApiGateway::Model",
            "AWS::ApiGateway::RequestValidator",
            "AWS::ApiGateway::Resource",
            "AWS::ApiGateway::RestApi",
            "AWS::ApiGateway::Stage",
            "AWS::ApiGateway::UsagePlan",
            "AWS::ApiGateway::UsagePlanKey",
            "AWS::ApiGateway::VpcLink",
            "AWS::Athena::NamedQuery",
            "AWS::Athena::WorkGroup",
            "AWS::CloudFront::Distribution",
            "AWS::CloudFront::CloudFrontOriginAccessIdentity",
            "AWS::CloudFront::StreamingDistribution",
            "AWS::CloudWatch::Alarm",
            "AWS::CloudWatch::AnomalyDetector",
            "AWS::CloudWatch::CompositeAlarm",
            "AWS::CloudWatch::Dashboard",
            "AWS::CloudWatch::InsightRule",
            "AWS::Cognito::IdentityPool",
            "AWS::Cognito::IdentityPoolRoleAttachment",
            "AWS::Cognito::UserPool",
            "AWS::Cognito::UserPoolClient",
            "AWS::Cognito::UserPoolDomain",
            "AWS::Cognito::UserPoolGroup",
            "AWS::Cognito::UserPoolIdentityProvider",
            "AWS::Cognito::UserPoolResourceServer",
            "AWS::Cognito::UserPoolRiskConfigurationAttachment",
            "AWS::Cognito::UserPoolUICustomizationAttachment",
            "AWS::Cognito::UserPoolUser",
            "AWS::Cognito::UserPoolUserToGroupAttachment",
            "AWS::DynamoDB::Table",
            "AWS::EC2::Volume",
            "AWS::EC2::VolumeAttachment",
            "AWS::EC2::Instance",
            "AWS::EC2::EIP",
            "AWS::EC2::EIPAssociation",
            "AWS::EC2::NetworkInterface",
            "AWS::EC2::NetworkInterfaceAttachment",
            "AWS::EC2::SecurityGroup",
            "AWS::EC2::SecurityGroupIngress",
            "AWS::EC2::SecurityGroupEgress",
            "AWS::EFS::FileSystem",
            "AWS::EFS::MountTarget",
            "AWS::ElastiCache::CacheCluster",
            "AWS::ElastiCache::ParameterGroup",
            "AWS::ElastiCache::ReplicationGroup",
            "AWS::ElastiCache::SecurityGroup",
            "AWS::ElastiCache::SecurityGroupIngress",
            "AWS::ElastiCache::SubnetGroup",
            "AWS::Events::EventBus",
            "AWS::Events::EventBusPolicy",
            "AWS::Events::Rule",
            "AWS::FSx::FileSystem",
            "AWS::Inspector::AssessmentTarget",
            "AWS::Inspector::AssessmentTemplate",
            "AWS::Inspector::ResourceGroup",
            "AWS::KinesisAnalytics::Application",
            "AWS::KinesisAnalytics::ApplicationOutput",
            "AWS::KinesisAnalytics::ApplicationReferenceDataSource",
            "AWS::KinesisFirehose::DeliveryStream",
            "AWS::Kinesis::Stream",
            "AWS::Kinesis::StreamConsumer",
            "AWS::AmazonMQ::Broker",
            "AWS::AmazonMQ::Configuration",
            "AWS::AmazonMQ::ConfigurationAssociation",
            "AWS::RDS::DBCluster",
            "AWS::RDS::DBClusterParameterGroup",
            "AWS::RDS::DBInstance",
            "AWS::RDS::DBParameterGroup",
            "AWS::RDS::DBSubnetGroup",
            "AWS::RDS::EventSubscription",
            "AWS::RDS::OptionGroup",
            "AWS::Route53::RecordSet",
            "AWS::Route53::HostedZone",
            "AWS::Route53::HealthCheck",
            "AWS::Route53::RecordSetGroup",
            "AWS::S3::Bucket",
            "AWS::S3::BucketPolicy",
            "AWS::SageMaker::CodeRepository",
            "AWS::SageMaker::Endpoint",
            "AWS::SageMaker::EndpointConfig",
            "AWS::SageMaker::Model",
            "AWS::SageMaker::NotebookInstance",
            "AWS::SageMaker::NotebookInstanceLifecycleConfig",
            "AWS::SageMaker::Workteam",
            "AWS::SES::ConfigurationSet",
            "AWS::SES::ConfigurationSetEventDestination",
            "AWS::SES::ReceiptFilter",
            "AWS::SES::ReceiptRule",
            "AWS::SES::ReceiptRuleSet",
            "AWS::SES::Template",
            "AWS::SDB::Domain",
            "AWS::SNS::Subscription",
            "AWS::SNS::Topic",
            "AWS::SNS::TopicPolicy",
            "AWS::SQS::Queue",
            "AWS::SQS::QueuePolicy",
            "AWS::WorkSpaces::Workspace",
            "AWS::AutoScaling::AutoScalingGroup",
            "AWS::AutoScaling::LaunchConfiguration",
            "AWS::AutoScaling::LifecycleHook",
            "AWS::AutoScaling::ScalingPolicy",
            "AWS::AutoScaling::ScheduledAction",
            "AWS::CertificateManager::Certificate",
            "AWS::CloudFormation::Designer",
            "AWS::CloudFormation::WaitCondition",
            "AWS::CloudFormation::WaitConditionHandle",
            "AWS::CodeBuild::Project",
            "AWS::CodeBuild::ReportGroup",
            "AWS::CodeBuild::SourceCredential",
            "AWS::CodeCommit::Repository",
            "AWS::CodeDeploy::Application",
            "AWS::CodeDeploy::DeploymentConfig",
            "AWS::CodeDeploy::DeploymentGroup",
            "AWS::DMS::Certificate",
            "AWS::DMS::Endpoint",
            "AWS::DMS::EventSubscription",
            "AWS::DMS::ReplicationInstance",
            "AWS::DMS::ReplicationSubnetGroup",
            "AWS::DMS::ReplicationTask",
            "AWS::ElasticLoadBalancingV2::Listener",
            "AWS::ElasticLoadBalancingV2::ListenerCertificate",
            "AWS::ElasticLoadBalancingV2::ListenerRule",
            "AWS::ElasticLoadBalancingV2::LoadBalancer",
            "AWS::ElasticLoadBalancingV2::TargetGroup",
            "AWS::ElasticLoadBalancing::LoadBalancer",
            "AWS::MediaConvert::JobTemplate",
            "AWS::MediaConvert::Preset",
            "AWS::MediaConvert::Queue",
            "AWS::MediaStore::Container",
            "AWS::Glue::Classifier",
            "AWS::Glue::Connection",
            "AWS::Glue::Crawler",
            "AWS::Glue::Database",
            "AWS::Glue::DataCatalogEncryptionSettings",
            "AWS::Glue::DevEndpoint",
            "AWS::Glue::Job",
            "AWS::Glue::MLTransform",
            "AWS::Glue::Partition",
            "AWS::Glue::SecurityConfiguration",
            "AWS::Glue::Table",
            "AWS::Glue::Trigger",
            "AWS::Glue::Workflow",
            "AWS::KMS::Key",
            "AWS::KMS::Alias",
            "AWS::LakeFormation::DataLakeSettings",
            "AWS::LakeFormation::Permissions",
            "AWS::LakeFormation::Resource",
            "AWS::Lambda::Alias",
            "AWS::Lambda::EventInvokeConfig",
            "AWS::Lambda::EventSourceMapping",
            "AWS::Lambda::Function",
            "AWS::Lambda::LayerVersion",
            "AWS::Lambda::LayerVersionPermission",
            "AWS::Lambda::Permission",
            "AWS::Lambda::Version",
            "AWS::SecretsManager::ResourcePolicy",
            "AWS::SecretsManager::RotationSchedule",
            "AWS::SecretsManager::Secret",
            "AWS::SecretsManager::SecretTargetAttachment",
            "AWS::SecurityHub::Hub",
            "AWS::StepFunctions::Activity",
            "AWS::StepFunctions::StateMachine",
            "AWS::SSM::Parameter",
            "AWS::Transfer::Server",
            "AWS::Transfer::User",
            "AWS::WAF::ByteMatchSet",
            "AWS::WAF::IPSet",
            "AWS::WAF::Rule",
            "AWS::WAF::SizeConstraintSet",
            "AWS::WAF::SqlInjectionMatchSet",
            "AWS::WAF::WebACL",
            "AWS::WAF::XssMatchSet",
        )

        resources = cfn.get_resources()

        for resource_name, resource_values in resources.items():
            path = ["Resources", resource_name]
            res_type = resource_values.get("Type")
            self.logger.debug("Validating %s as supported by AMS", resource_name)

            if not res_type.startswith(valid_resource_types):
                message = "AMS - {0} Resource not supported"
                matches.append(RuleMatch(path, message.format("/".join(map(str, path)))))

        # Patch system does not support combinations of EC2+ASG
        resource_types = set([resource_values.get("Type") for _, resource_values in resources.items()])

        if "AWS::EC2::Instance" in resource_types and "AWS::AutoScaling::AutoScalingGroup" in resource_types:
            message = "AMS - Resources 'AWS::EC2::Instance' and 'AWS::AutoScaling::AutoScalingGroup' are not supported in the same stack by the AMS Patch system"
            matches.append(RuleMatch(path, message))

        return matches
