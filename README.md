### Docker AWS Elastic Beanstalk
#### Build NGINX, PHP environment 

For Mac users to remove the MACOSX folder from the .zip file. Then you can upload the .zip file to deploy your app.
- zip -d filename.zip __MACOSX/\*

### Dockerrun.aws.json: 

- Check that code and be careful when you build your docker configuration:

```
{
  "sourceVolume": "awseb-logs-nginx",    // nginx is the container name
  "containerPath": "/var/log/nginx"      // here the nginx is not related with the container name. I have just set the path on my own
},
```

### ECR
 - You can create your custom image and upload it in your ECR Repository and use it in your Dockerrun.aws.json file
 ```
 "containerDefinitions": [
    {
      "name": "php",
      "image": "1234567890123.dkr.ecr.eu-central-1.amazonaws.com/myimage:latest",
      "essential": true,
  ```
  
  Add in the Role __aws-elasticbeanstalk-ec2-role__ the Policy __AmazonEC2ContainerRegistryReadOnly__ so that Dockerrun.aws.json has read access to your ECR Repositories
  
  - To push your local created image you need an IAM User with Policy __AmazonEC2ContainerRegistryFullAccess__, install AWS CLI, configure AWS Authorization(command: aws configure)
  
### Bitbucket Deployments 

We create a `bitbucket-pipelines.yml` file in the `root` folder of our project.
1. Build
2. Deploy

```
image: atlassian/default-image:2

pipelines:
  branches:
    test:
      - step:
          name: "Build and Test"
          script:
            - echo "Create ZIP file"
            - zip -r application.zip *
          artifacts: 
            - application.zip
      - step:
          name: "Deploy to Test"
          deployment: test
          trigger: manual
          script:
            - pipe: atlassian/aws-elasticbeanstalk-deploy:0.5.5
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: "eu-central-1"
                APPLICATION_NAME: "testapp"
                ENVIRONMENT_NAME: 'newenv'
                ZIP_FILE: "application.zip"
                S3_BUCKET: 's3bucketname'
                VERSION_LABEL: $(date +%d-%m-%Y_%H:%M:%S)_$BITBUCKET_BUILD_NUMBER
  tags:
    v-*:
      - step:
          name: "Build and Test"
          script:
            - echo "Create ZIP file"
            - zip -r application.zip *
          artifacts: 
            - application.zip
      - step:
          name: "Deploy to Production"
          deployment: production
          trigger: manual
          script:
            - pipe: atlassian/aws-elasticbeanstalk-deploy:0.5.5
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: "eu-central-1"
                APPLICATION_NAME: "testapp"
                ENVIRONMENT_NAME: 'phpenv'
                ZIP_FILE: "application.zip"
                S3_BUCKET: 's3bucketname'
                VERSION_LABEL: $BITBUCKET_TAG

```
Create an IAM User with Permissions S3FullAccess and BeanstalkFullAccess and use the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY for the deployment process
