![](img/2022-10-13-10-18-20.png)
# 🎓T3 Creating a CI/CD pipeline in GitLab
in this tutorial you will set up a basic gitlab Continous Integration and Deployment (CI/CD) pipeline that executes the following jobs:
- Build a web application project from source
- Package the build into a docker container
- Publish the container on the repository's GitLab container registry
- Deploy the container to AWS Elastic Beanstalk

prerequisites:
- Credentials for an AWS tenant
- Access to the AWS web console
- Credentials to access the AWS API's
- A fork or import of this git repository

✅**TASK:** Fork this repository to create your own repository to use during this tutorial.

# AWS Elastic Beanstalk
Elastic Beanstalk is an AWS service that lets us easily deploy and scale web applications. In order to deploy some code we simply provide a containerized build and initiate a version update.
Elastic Beanstalk will automaticly create and manage an EC2 instance and S3 Bucket for our application environment and to store our application's data.
![](img/2022-10-13-10-25-01.png)
![](img/2022-10-13-10-25-35.png)

✅**TASK:** Read the following pages in order to understand the basic concepts of AWS Elastic Beanstalk:
- https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/Welcome.html
- https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.html

# GitLab for DevOps
GitLab includes many features that can assist an organization in setting op a DevOps toolchain. By leveraging these features it is possible to run a significant part of the DevOps lifecycle wihtin Gitlab itself. This eliminates the complexity of setting up a toolchain that integrate a lot of different platforms.
![](img/2022-10-13-10-54-56.png)
Another advantage of using GitLab is that it allows for organizations and individuals to host their own instance. If an organisation ever feels the need to move away from GitLab's services, they can simply move all of their repositories including their CI/CD pipelines onto another GitLab instance hosted by themselves or a trusted third party.
Meaning they are not locked into a single provider's ecosystem for developing and maintaining their applications or Infrastructure As Code (IaC).

✅**TASK:** During this tutorial we will be using the GitLab features listed below. Get familiar with these concepts by taking a look at the pages of the GitLab documentation included with each item:
- GitLab CI/CD Pipelines
    - To describe the required automated jobs and stages that need to be performed when a new version of our application is merged into the main branch
    - https://docs.gitlab.com/ee/ci/pipelines/
- GitLab Runners
    - To execute jobs within a termporary execution environment
    - https://docs.gitlab.com/runner/
- GitLab CI/CD Variables
    - To securely store our AWS credentials within GitLab and to access the GitLab Container Registry from within our jobs
    - https://docs.gitlab.com/ee/ci/variables/
    - https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
- GitLab CI/CD Job artifacts
    - To pass our build between jobs
    - https://docs.gitlab.com/ee/ci/pipelines/job_artifacts.html
- GitLab CI/CD services
    - To run the docker deamon as a service, allowing us to build docker images from within a docker container
    - https://docs.gitlab.com/ee/ci/services/
- GitLab Container Registry
    - for storing docker images containing the application builds
    - https://docs.gitlab.com/ee/user/packages/container_registry/

# Git Workflow
When using git to collaboratively create and maintain applications or IaC projects we need everyone that contributes code to a repository to use the same workflow when dealing with branches and merge requests. this is often called a Git Workflow. An aggreed upon Git Workflow will reduce the amount of useless branches and increase the speed at which changes can be safely introduced to the main branch of the project.
There are many different Git Workflow strategies, it depends on the organisation structure which strategy is the most benificial.

✅**TASK:** Read the following article about Git Workflows to get familiar with the most common strategies: https://about.gitlab.com/topics/version-control/what-is-git-workflow/

## Feature branch workflow
We will set up our GitLab repository in a way to enforce the Feature Branch workflow. In order to achieve this we use the Protected Branches feature within GitLab: https://docs.gitlab.com/ee/user/project/protected_branches.html

✅**TASK:** Within you GitLab repository make the following changes:
- Navigate to Settings > Repository > Protected Branches
- Click "Expand" and scroll down to the main branch
- Change the Allowed to push dropdown from "Maintainers" to "No one"
![](img/2022-10-13-12-59-38.png)
By making this change it is no longer possible to push directly to the main branch. Any change to the main branch will have to be made by following the Feature Branch workflow: https://docs.gitlab.com/ee/gitlab-basics/feature_branch_workflow.html

The maintainer role will be responsible for reviewing and approving merges into the main branch.

# Creating a basic CI/CD pipeline 
## 1) creating initial GitLab pipeline
GitLab uses the '.gitlab-ci.yml' file to store the stages and jobs that describe the repository's pipeline. When initially created, a respository does not contain this file. We will use the GitLab Web IDE to create this file. The Web IDE can be used to make changes to text files, commit them to your repository and quickly see the results in the web interface. This is especially usefull when working on pipeline configuration. You are ofcourse free to use your own IDE (like vscode) to make the necesary changes.

✅**TASK:** Create the initial GitLab pipeline.

- Within your GitLab repository click on the "Web IDE" button in the upper right corner
    - ![](img/2022-10-13-13-04-00.png)
- The Web IDE will open, you can create a new file by clicking the new file icon in the left sidebar
    - ![](img/2022-10-13-13-08-45.png)

- When prompted for a filename you can simply click the suggested '.gitlab-ci.yml' file
    - ![](img/2022-10-13-13-10-30.png)

- Within this file we will define our first (useless) basic pipeline in order to get familiar with the GitLab interface. Lets create a single job that prints 'Hello World' in the logs:
```yml
saying hello:
    image: alpine
    script:
        - touch hello.txt
        - echo "Hello World!" >> hello.txt
        - cat hello.txt
```
- The name of our job is "saying hello" and we defined that the job should run using the alpine linux image.
Now create a new commit by clicking "Create commit...". You will not be allowed to commit to the main branch. So instead we create a new branch for our feature. Fill in a name for your feature branch and un-check the 'Start a new merge request' checkbox for now.
    - ![](img/image.png.png)
- After commiting your changes you will see that your pipeline has started running in the lower left corner.
    - ![](img/2022-10-13-13-29-58.png)
- Click the pipeline ID to open it adn you will see the pipeline interface. Your job might still be running.
Click the "saying hello" job to see its logs.
![](img/2022-10-13-13-33-13.png)
- It looks like our job has been executed successfully. Note that our job was automatically assigned to the 'Test' stage since we did not define a stage within the '.gitlab-ci.yml' file.
- Now lets expand on our pipeline to add another job that has to be executed before our first job. Go back to the Web IDE and make sure to select your feature branch in the upper left corner. Open the '.gitlab-ci.yml' file and make the following changes.
```yml
stages:
    - write
    - say

writing hello:
    image: alpine
    stage: write
    script:
        - touch hello.txt
        - echo "Hello World!" >> hello.txt
    artifacts:
        paths:
            - hello.txt

saying hello:
    image: alpine
    stage: say
    script:
        - cat hello.txt
```
- we have now defined our own sequence of stages called 'write' and 'say'. We added a new job called 'writing hello' that will write the message to the 'hello.txt' file within our alpine image. This job has been assigned to the 'write' stage and will upload the 'hello.txt' to the GitLab server as an artifact. 
- The creation of the 'hello.txt' file no longer takes place in the 'saying hello' job, instead it has been assigned to the 'say' stage and simple shows the content of the 'hello.txt" file which will be downloaded before the script is initiated.
- Now commit these changes and have a look at the pipeline to see what happens.
![](img/2022-10-13-13-53-09.png)
- we now have two jobs each within their own stage.
![](img/2022-10-13-13-54-25.png)
- The 'writing hello' job has created the file and uploaded it to the GitLab server as an artifact.
![](img/2022-10-13-13-58-14.png)

- The 'saying hello' job has been executed after the 'writing hello' job was finished and downloaded the artifacts before executing the script.

## 2) Setting up an AWS Elastic Beanstalk application
We now know how to create a basic pipeline that can execute scripts and pass artifacts. We still need an environment to run our web application once it has been build. For this we will create an AWS Elastic Beanstalk application.
![](img/2022-10-13-14-07-26.png)

✅**TASK:** Create an example application in Elastic Beanstalk
- Open the AWS web console and search for Elastic Beanstalk
- Since you have no Elastic Beanstalk Envrionments yet you will see a getting started guide. Simple click "Create Application" to get started.
![](img/2022-10-13-14-14-23.png)
- Give the application a name
- Leave the Application tags empty
- Select "Docker" for the Platform and leave the rest of the options to their default setting
- For the Application code we will use the Sample application as a starting point
![](img/2022-10-13-14-17-29.png)
- Click "Configure more options" and scroll down to Security and click "edit"
- Change the security settings to match the following options
![](img/2022-10-13-15-58-16.png)
- Save the changes and create the application
- Setting up the application and it's environment will take a few minutes
- Once the application has finished initializing you will see the following screen where you can find the URL of your deployed application.
![](img/2022-10-13-16-06-03.png)
- When you click this URL the sample application should be visible
![](img/2022-10-13-16-07-11.png)

We now have a running and scalable environment to deploy docker containers into!

✅**TASK:** Within the AWS console have a look at your S3 buckets and EC2 instances to see if anything has changed.


## 3) Packaging a build using Docker
In this repository you will find some basic example website in the /demo-website directory. We will package this website in a docker container together with nginx as a webserver.
### 3.1) Create the Dockerfile
 ✅**TASK:** Using the GitLab Web IDE (or your IDE of choice) create a Dockerfile at the root of this repository. We will simple use the nginx image from docker hub as a base and copy our website into the correct directory.

 ```dockerfile
FROM nginx:1.23.1-alpine
COPY demo-website /usr/share/nginx/html
 ```

Note that we use a specific version tag instead of simply the latest version of nginx. Whenever we are building docker images within a pipeline we want all changes to be managed by our repository's version control to assure we have consistent results when running the pipeline at a later date. The latest version might change tomorrow which means that a build today might not be the same as a build tomorrow.

We also selected the alpine version which is smaller. It is always advised to use more compact version of an image when dealing with them in a pipeline since they have to be downloaded everytime the pipeline is executed.

 ✅**TASK:** go to https://hub.docker.com/_/nginx and look for the latest available alpine release of nginx. Change the Dockerfile if necessary.

### 3.2) Build the docker image within the pipeline
We now have a Dockerfile that is ready to be built. We could build it on our local machine and push it to AWS Beanstalk but that would require some manual steps. Lets look at our '.gitlab-ci.yml' file and implement a job to build our docker image.

We are using the GitLab Runners with the Docker executor. This means that our jobs are running within a docker image that we get to choose. To build a docker image we will have to run docker within this Runner's docker image. We need Docker in Docker (dind)! https://hub.docker.com/_/docker

The Docker in Docker image only includes the client by default. In order build images we need both the docker client and docker deamon. For this reason we will need to run the docker deamon as a service to our docker in docker image. We once again use fixed version tags so make sure to look for the latest available versions.

To identify our docker image we also add some tags using the -t option of the docker build command. In order to always have a unique tag we use the GitLab CI/CD predefined variables to add the following tags:
- -t $CI_REGISTRY_IMAGE
    - This will resolve into the GitLab Repository's container registry URL
- -t \$CI_REGISTRY_IMAGE:$CI_PIPELINE_IID
    - This will resolve into the same URL appended by a unique ID for the pipeline it was built in

You can see a list of all predefined variables here: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html

✅**TASK:** Remove the previous '.gitlab-ci.yml' and create the following '.gitlab-ci.yml' file. Make sure you are making changes in your feature branch.

```yml
stages:
    - package

build docker image:
    stage: package
    image: docker:20.10.12
    services:
        - docker:20.10.12-dind
    script:
        - docker build -t $CI_REGISTRY_IMAGE -t $CI_REGISTRY_IMAGE:$CI_PIPELINE_IID .
        - docker image ls

```
Commit the changes (don't make a merge request) and wait for the pipeline to run. Then have a look at the logs.

![](img/2022-10-13-18-18-40.png)

Wait for the job to finish

![](img/2022-10-13-18-19-48.png)

We can see the process of the docker image layers being created to build the nginx image.

![](img/2022-10-13-18-21-53.png)

And here we see the step where we copied the webpage into the container. Aswell as the tags that we created to identify the container.

![](img/2022-10-13-18-23-36.png)

Great we were able to build a docker image inside our pipeline! But where did the container image go? As you might have guessed it was destroyed as soon as the runner destroyed our job container. We will need a place to store our packaged containers in order to pass them to AWS Beanstalk. This is where the Container Registry comes into play.

## 4) Push to GitLab Container Registry
Containers are not just regular files that we can simply handle as an asrtifact within our pipeline. We could publish our image to Docker Hub and pull it to AWS Beanstalk from there. But Docker Hub is a public registry and we might want our images to remain private. For this reason GitLab includes a Container Registry for each git repository. We will simple push our image from within the pipeline to this private registry in order to preserve the docker image.

You can find the GitLab Container Registry by navigating to Packages & Container Registries > Container Registry.

Because it is a private registry we will need to authenticate before we can push. Luckily there are some predefined variables we can use to both contact the registry and authenticate our job container.

✅**TASK:** Add the following two commands to your 'build docker image' job. make sure to replace the \<placeholders\> with the correct predefined variables.

Add this as the first command in the script:
```bash
echo <password> | docker login -u <username> <registry URL> --password-stdin
```
Add this as the last command in the script:
```bash
docker push --all-tags <image name> 
```
Commit your changes and check if your image has landed in the Container Registry. If you see your image sucessfully published in the registry you can continue to the next step. It should look something like this:

![](img/2022-10-13-18-51-51.png)

## 5) Deploying to AWS Beanstalk
We now have our container ready in the GitLab Container Registry. The only step that is left is getting AWS Elastic Beanstalk to pull this image as its latest application version. We could do this manually in the AWS Console. But with the power of AWS CLI and GitLab jobs we can automate this task.

The following actions need to happen in order for the application to deploy:
- AWS Beanstalk needs to be informed about which registry to contact and what image to pull from it
- AWS Beanstalk needs to authenticate to the GitLab Container Registry and pull the image
- AWS Beanstalk needs to implement the image as a new version of the application

Which means our job needs to authenticate in order to use AWS CLI and AWS Beanstalk needs to authenticate in order to access the image on the Container Registry. We can already authenticate to AWS using our AWS credentials (aws access key id and aws secret access key). We still need to create a way for AWS EB to authenticate to our Container Registry.

✅**TASK:** In GitLab navigate to Settings > Repository > Deploy tokens. Click Expand and fill in the following information:

![](img/2022-10-13-19-53-51.png)

Click 'Create deploy token' and make sure to copy the token to some secure location. You will only get to see it once. We will use this token later to authenticate AWS EB to our Container Registry.

In order to use AWS CLI from within a GitLab Job we need to find a way to securely authenticate without hardcoding our credentials in the '.gitlab-ci.yml' file. Previously we used predefined environment variabels to authenticate to our GitLab Registry. We can do something similar for accessing the AWS API's through the AWS CLI.

✅**TASK:** Check out the GitLab documentation about CI/CD variables and set the following variables at the project level. For now we will leave these variables 'unprotected' in order to have access to them from our feature branch.
- Key: AWS_ACCESS_KEY_ID
    - Value: your aws access key id
- Key: AWS_SECRET_ACCESS_KEY
    - Value: your aws secret access key
- Key: AWS_SESSION_TOKEN
    - Value: your aws session token
- Key: AWS_DEFAULT_REGION
    - Value: us-east-1
- Key: AWS_S3_BUCKET
    - Value: the name of the S3 Bucket created by Elastic Beanstalk
- Key: GITLAB_DEPLOY_TOKEN
    - Value: "AWS:" followed by the deploy token AWS EB will use to contact the GitLab Container Registry
    - for example "AWS:CqCusfioKKjdsf9f2"
- Key: EB_ENV_NAME
    - The name of the AWS EB Application you have created
- Key: EB_APP_NAME
    - The name of the AWS EB Environment you have created

These variables will now be available within your pipeline job's environment variables. AWS CLI will automaticially look for these variables in order to connect to the AWS APIs.

✅**TASK:** Now that we can use AWS CLI within our pipeline we can add the following job to our '.gitlab-ci.yml' file:
```yml
deploy to production:
    stage: deploy
    image:
        name: amazon/aws-cli:2.4.11
        entrypoint: [""]
    before_script:
        - yum install -y gettext
    script:
        - aws --version
        - export DEPLOY_TOKEN=$(echo $GITLAB_DEPLOY_TOKEN | tr -d "\n" | base64)
        - envsubst < AWS-EB/Dockerrun.aws.json > Dockerrun.aws.json
        - envsubst < AWS-EB/auth.json > auth.json
        - aws s3 cp Dockerrun.aws.json s3://$AWS_S3_BUCKET/Dockerrun.aws.json
        - aws s3 cp auth.json s3://$AWS_S3_BUCKET/auth.json
        - aws elasticbeanstalk create-application-version --application-name "$EB_APP_NAME" --version-label $CI_PIPELINE_IID --source-bundle S3Bucket=$AWS_S3_BUCKET,S3Key=Dockerrun.aws.json
        - aws elasticbeanstalk update-environment --application-name "$EB_APP_NAME" --version-label $CI_PIPELINE_IID --environment-name "$EB_ENV_NAME"
```
make sure to add 'deploy' to the list of stages at the beginning of the file.

This job will run in a container that has AWS CLI already installed. Before the script runs we also install the gettext package that includes the envsubst utility we will need in our script.
The script performs the following actions:
- Show the AWS CLI version in the logs
- Substitute the variables in the Dockerrun.aws.json file and auth.json file with the values in the Environment variables
- Upload the Dockerrun.aws.json and auth.json file to the EB S3 Bucket
    - These files include the instructions that AWS EB will use to create a new version of the application aswell aw the authentication token that is needed to access the GitLab Container Repository
- Create a new AWS EB application version by telling AWS EB to look at the Dockerrun.aws.json file that was uploaded to the S3 Bucket
- Update the AWS EB Envrionment with the new version

✅**TASK:** Analyse the actions of this job and make sure there are no mistakes. If you find something that does not match your expectations you chould change it before creating a new commit. If you are sure everything is correct try running the pipeline and wait for AWS EB to deploy your webpage.

![](img/2022-10-13-20-41-37.png)
The AWS EB environment is updating. This can take a few minutes.

![](img/2022-10-13-21-07-31.png)

![](img/2022-10-13-21-07-09.png)
We have lift off!!

![](img/2022-10-13-21-06-31.png)
You should now see this page when visiting the application's URL.

# Now it is up to you!
In the '/web-app' directory you can find a web application that needs to be built using yarn. Simply run the following commands in the '/web-app' directory.

```bash
yarn install
yarn lint
yarn test
yarn build
```

✅**TASK:** You are tasked with setting up a pipeline to automatically deploy a reat application to AWS EB. Create a new branch in which you setup a new pipeline that includes the following stages and jobs:
- Stages
    - Build
    - Package
    - Deploy
- Jobs
    - build web application
        - performs the yarn build and stores them as in artifact in the /build directory
    - package web application
        - package the /build into an nginx docker image
    - deploy to aws
        - deploy the image from the GitLab registry to AWS EB

Once you were able to run this pipeline sucessfully, create e merge request to merge this set-up into the main branch. Assign Bram and Alexander to this merge request.

Good Luck!