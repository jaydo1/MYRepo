# Step 2 - Using Hierarchy

To some this may seem counter intuitive, since all we're building is a single instance, however if you extrapolate what we've done here, it becomes far easier to manage a full stack (stack of stacks) in this way. I know that if I want to add a security rule, I can do it in the resources template, without touching the instances. If I want to add a security group, I'm also not going to effect the instance template until I want to pass the details onto it, via the master/parent template. In everyday usage, this prevents constant updating of the parent and instance stacks, which increase the risk of stack failure if they're always included and the stack is large. Following on from this, as you will see in step 3, you can add resources, like a database, without having to change the main or hosts template, if you want to pass values like the database name to your instance, then of course you do need to update the hosts stack otherwise it can't learn about that dynamically, however this method still avoids overly frequent updates.

## What's happening here?
Looking at the main template, we can see that we've called the AWS::CloudFormation::Stack type twice, the first is for a template named simple-instance-resources.cfn.template, which as is as it sounds a separate template file that expects values to be fed to it. The way in which that is done is to use the "Parameters" section in this declaration. If we added nothing here, then it would be like trying to build a stack in the last example without entering any values, therefore causing the stack to fail. In this example, the expected values that are required for the resources stack to build are as follows:

```sh

          "VpcId"            				: { "Ref" : "VpcId" },
          "AvailabilityZone1"            	: { "Ref" : "AvailabilityZone1" },
          "InternetGateway"    				: { "Ref" : "InternetGateway" },
          "PubNet01"            			: { "Ref" : "PubNet01" },
          "YourPublicRange"            		: { "Ref" : "YourPublicRange" }

```

As we can see they are the same values that we saw last time, in Step1, only this time the PubNet01 is expecting a CIDR notation instead of a subnet ID, this is because we're going to create the subnet with this stack instead of expect it to be available. The VPC and Internet Gateway are still expected, however these could be easily created in a different CloudFormation template if one wished. As a practice, keeping the VPC and resources within it separate is a good idea, needless to say safer, if you have a roll back failure on your VPC because of repeated updates and an eventual error, you'd have to delete everything within the VPC, or begin managing it manually. CloudFormation at this point can normally discern what it must build first in order to be successful, in this case, because we are specifying another stack that relies on outputs from the resources stack, it will build first. You can add the 'DependsOn' attribute at the same level as the stack properties, this will be shown in a later step.

Once the resources stack is built (using the resources template that the main template calls), CloudFormation records some outputs that we specify, in particular for this to work we need the ID for the subnet that we are building this simple Amazon Linux Instance into, as well as the security group ID. Everything else is covered by defaults or values that are already set. Remember that if the Parameters are not fed values in either of the two child stacks, the build will fail. Once at this stage, where the Instance template has begun and all values are present, we shouldn't get a failure.

