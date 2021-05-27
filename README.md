# Creating a Lambda function to run a bash shell script using Docker :whale2:

 
## Intro 

Lambda does not include shell scripts, so this document uses python to call a shell script. 
You will need docker installed on your laptop and awscli access to the AWS account. 
It’s best to get the script working before creating a new lambda image, because of the time involved in image deployment. 
For this document the example project name will be project-rain 

 
## Initial  Setup 

Create a directory on your laptop called **"Your Project Name"**. Clone the repository, but push to a new project based repository.  
Edit the script.sh file to include your code. The script.sh file needs to exit with **“/usr/local/bin/python -m awslambdaric app.handler”**, without this you’ll get a lambda execution error. Any error handling within the script can be done using AWS SNS. 
If you need to install extra packages, add these to the apt-get install command in the Dockerfile. 


## Bespoke Images 

If you need to install extra packages and test them on the image, build the image with the ENTRYPOINT line commented out, this will allow you to logon to the image. Docker build it, start it and logon:
``` 
docker build -t project-rain .
docker run -dt project-rain bash
docker ps   (use the Name in the next command)
docker exec -it <Container Name> /bin/bash
```

To stop and remove a container:
```
docker stop <Container Name>
docker rm <Container Name>
```
To delete a Docker image:
```
docker images   (use the IMAGE ID in the next command)
docker rmi -f <IMAGE ID>
```

## Build and Push to ECR

You’ll need to create a ECR repository and make a note of the URL. 
When the the script.sh is ready and if it needs to be, the Dockerfile has been edited, you're ready to build the image:
```
docker build -t project-rain .
```
Then tag it with the ECR URL:
```
docker tag project-rain 123456789012.dkr.ecr.eu-west-1.amazonaws.com/project-rain
```
You then need to logon to AWS
```
aws ecr get-login-password [--profile <PROFILE NAME>]| docker login --username AWS --password-stdin 123456789012.dkr.ecr.eu-west-1.amazonaws.com
```
And then you can push the image to ECR:
```
docker push 123456789012.dkr.ecr.eu-west-1.amazonaws.com/project-rain
```


## Create the Lambda Function 

Select “Create function” and then select the “Container image” option, select the ECR image you pushed to the repository. The function needs a role attached to it, to give it any necessary AWS access.
Remember to edit the memory and timeout settings, as the defaults are low.

 
# APPENDIX 

***Dockerfile*** 
> The docker image build file.

***app.py*** 
> The app.handler python script. 

***script.py*** 
> The python startup script, that calls the shell script. 

***script.sh*** 
> The shell script, only the exit code included here.

