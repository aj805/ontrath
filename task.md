# Exercise: Infrastructure and Code for an API Endpoint

## Task
Create a basic API endpoint which responds to HTTP GET requests and returns a JSON
payload in the form {"The current epoch time": <EPOCH_TIME>} where <EPOCH_TIME> is an
integer representing the current epoch time in seconds.
We will test your endpoint with Curl. It must be accessible over the internet and should not run
on localhost (127.0.0.1).

## Details
You must provide a script or Makefile which will provision the infrastructure and code for your
API to AWS. You must also include documentation in a ReadMe.md file which explains how to
run your deployment script. Please specify the set of tools we will need to deploy and run your
application e.g. kubectl, Terraform, the AWS CLI.
You must provide the above in a GitHub repository which we can access.
You can assume that we have proper credentials (with administrator access) to an AWS account
that we manage. We need to be able to provision/deploy your API in our account by following
your documentation. It should not take more than 15-20 minutes to deploy your solution and
have a running API endpoint which we can verify.
You may deploy this API with whatever toolset you choose but the API code must be
containerized. For example, you can use Terraform, CloudFormation/CDK, Pulumi and whatever
tools and scripts you prefer.
You do not need to include code to install CLI tools e.g. the AWS CLI, Terraform, Terragrunt,
Helm, etc. For example, if your solution requires Terraform and Helm, you only need to
document which versions of Terraform and Helm we need to deploy your solution.
You are welcome to include additional materials/resources as well, for example diagrams, unit
tests, linting, CI/CD. However, you do not need to add "everything". We are interested in a
solution that is intuitive, clean and most of all, works.