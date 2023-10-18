import boto3
import time
import sys

# EC2 client object
ec2_client = boto3.client("ec2")

# try catch to handle possible errors
try:
    # check if arguments are passed
    if len(sys.argv) > 1:
        # check if 2 arguments are passed
        if len(sys.argv) == 3:
            ami = sys.argv[1]
            name = sys.argv[2]
        # incorrect amount of arguments
        else:
            raise Exception("The number of arguments is in correct. Only pass 2 arguments (AMI ID and name)!")
        
    # no arguments -> show prompt to user
    else:
        # show user a prompt with OS options
        print("1. Debain 11\n2. Ubuntu Server 22.04 LTS\n3. Windows Server 2022 Base")

        # ask the choice the user wants
        choice = input("Select your OS (number): ")

        # check which OS is selected
        if choice == "1":   
            # ami id Debain 11
            ami = "ami-0c20d96b50ac700e3" 
        elif choice == "2":
            # ami id Ubuntu server 22.04 LTS
            ami = "ami-053b0d53c279acc90"
        elif choice == "3":
            # ami id Windows Server 2022 Base
            ami = "ami-0be0e902919675894"
        # user gave a number that is not an option
        else:
            raise Exception("The number you gave is not an option!")
     
        # ask the name of the instance
        name = input("Enter the name of the instance: ")


    # create the instance with the selected ami and name
    instance = ec2_client.run_instances(ImageId = ami, MinCount=1, MaxCount=1,TagSpecifications=[{"ResourceType": "instance", "Tags":[{"Key":"Name", "Value":name}]}])
    
    # wait a few seconds before getting al info -> instance needs time to start up
    time.sleep(2)

    # get the  all the info from the instance -> gives a lot of info
    info_instance = ec2_client.describe_instances(InstanceIds=[instance["Instances"][0]["InstanceId"]])

    # get only part with the info that is needed
    spec_info_instance = info_instance["Reservations"][0]["Instances"][0]

    # output
    print("Name: {}\nImageId: {}\nInstanceId: {}\nInstanceType: {}\nAvailabilityZone: {}\nInstance State: {}\nPublic IPv4 DNS: {}\nPublic IPv4: {}".format(spec_info_instance["Tags"][0]["Value"], spec_info_instance["ImageId"],spec_info_instance["InstanceId"],spec_info_instance["InstanceType"],spec_info_instance["Placement"]["AvailabilityZone"],spec_info_instance["State"]["Name"], spec_info_instance["PublicDnsName"],spec_info_instance["PublicIpAddress"]))

# catch the erros that are raised 
except Exception as error:
    print(repr(error))

# catch any unexpected errosS
except:
    print("Something went wrong try again later!")
