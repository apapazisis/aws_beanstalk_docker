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
  default:
    - step:
        name: "Build and Test"
        script:
          - echo "Everything is awesome!"
          - zip -r application.zip *
        artifacts: 
          - application.zip
    - step:
        name: "Deploy to Production"
        deployment: production
        script:
          - pipe: atlassian/aws-elasticbeanstalk-deploy:0.5.5
            variables:
              AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
              AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
              AWS_DEFAULT_REGION: "eu-central-1"
              APPLICATION_NAME: "testapp"
              ENVIRONMENT_NAME: 'phpenv'
              ZIP_FILE: "application.zip"
              S3_BUCKET: 'nameofs3bucket'

```
