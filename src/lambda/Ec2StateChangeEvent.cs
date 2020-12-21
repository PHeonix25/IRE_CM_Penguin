// {
//    "id":"7bf73129-1428-4cd3-a780-95db273d1602",
//    "detail-type":"EC2 Instance State-change Notification",
//    "source":"aws.ec2",
//    "account":"123456789012",
//    "time":"2019-11-11T21:29:54Z",
//    "region":"us-east-1",
//    "resources":[
//       "arn:aws:ec2:us-east-1:123456789012:instance/i-abcd1111"
//    ],
//    "detail":{
//       "instance-id":"i-abcd1111",
//       "state":"pending"
//    }
// }

using System.Collections.Generic;

namespace lambda
{
    public class Ec2StateChangeEvent
    {

        public string Id { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("detail-type")]
        public string DetailType { get; set; }

        public string Time { get; set; }

        public string Region { get; set; }

        public List<string> Resources { get; set; }

        public detail Details {get;set;}
    }
    public class detail
        {
            [System.Text.Json.Serialization.JsonPropertyName("instance-id")]
            public string InstanceId { get; set; }
            public string State { get; set; }

        }
}