![](img/2022-10-13-10-18-20.png)
# 🎓T3 Creating a CI/CD pipeline in GitLab

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

### 3.2) Build the docker image within the pipeline

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

## 4) Push to GitLab Container Registry

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

✅**TASK:** Analyse the actions of this job and make sure there are no mistakes. If you find something that does not match your expectations you chould change it before creating a new commit. If you are sure everything is correct try running the pipeline and wait for AWS EB to deploy your webpage.

![](img/2022-10-13-20-41-37.png)
The AWS EB environment is updating. This can take a few minutes.

![](img/2022-10-13-21-07-31.png)

![](img/2022-10-13-21-07-09.png)
We have lift off!!

![](img/2022-10-13-21-06-31.png)
You should now see this page when visiting the application's URL.
