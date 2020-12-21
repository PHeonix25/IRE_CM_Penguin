using System;
using Amazon.Lambda.Core;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace lambda
{
    public class Function
    {
        public string FunctionHandler(Ec2StateChangeEvent input, ILambdaContext context)
        {
            Console.WriteLine($"Given '{input}', actioning now...");
            RemoveFromOctopusDeployServer(input.Details.InstanceId);
            return "All operations completed successfully.";
        }

        private void RemoveFromOctopusDeployServer(string instanceId)
        {
            Console.WriteLine($"Searching OctopusDeploy ('{Constants.OCTOPUSDEPLOY_APIURL}') for machines matching '{instanceId}'...");

            var endpoint = new Octopus.Client.OctopusServerEndpoint(Constants.OCTOPUSDEPLOY_APIURL, Constants.OCTOPUSDEPLOY_APIKEY);
            var repository = new Octopus.Client.OctopusRepository(endpoint);
            var machines = repository.Machines.List(partialName: instanceId);

            foreach (var machine in machines.Items)
            {
                Console.WriteLine($"Found machine '{machine}'. Deleting now.");
                repository.Machines.Delete(machine);
                Console.WriteLine($"Machine '{machine}' deleted.");
            }
        }
    }
}
