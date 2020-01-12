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

definitions:
  services:
    mysql:
      image: mysql:8.0.17
      environment:
        MYSQL_DATABASE: database
        MYSQL_USER: secret
        MYSQL_PASSWORD: secret
        MYSQL_ROOT_PASSWORD: root

  steps:
    - step: &composer
        name: Composer Install
        image:
          name: "00000000000.dkr.ecr.eu-central-1.amazonaws.com/image:latest"
          aws:
            access-key: $AWS_ECR_ACCESS_KEY_ID
            secret-key: $AWS_ECR_SECRET_ACCESS_KEY
        script: 
          - php -v
          - composer -V
          - composer install
          # - php artisan migrate
        artifacts:
          - vendor/**

    
    - step: &test
        name: Test Application
        image:
          name: "00000000.dkr.ecr.eu-central-1.amazonaws.com/image:latest"
          aws:
            access-key: $AWS_ECR_ACCESS_KEY_ID
            secret-key: $AWS_ECR_SECRET_ACCESS_KEY
        script: 
          - echo "run test"
          #- cat .env
          #- vendor/bin/phpunit --testdox
        services:
          - mysql
    
    
    - step: &build
        name: Building Application
        image: atlassian/default-image:2
        script:
          - zip -r application.zip *
        artifacts:
          - application.zip


    - step: &deploy
        name: Deploy to Elasticbeanstalk
        script:
          - pipe: atlassian/aws-elasticbeanstalk-deploy:0.5.5
            variables:
              ENVIRONMENT_NAME: $ENVIRONMENT_NAME
              AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
              AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
              AWS_DEFAULT_REGION: "eu-central-1"
              APPLICATION_NAME: "testapp"
              ZIP_FILE: "application.zip"
              S3_BUCKET: "s3bucketname"
              VERSION_LABEL: $(date +%d-%m-%Y_%H:%M:%S)_$BITBUCKET_BUILD_NUMBER
    
    
security: &security
  step:
    name: security:checker
    script:
      - curl -sS https://get.symfony.com/cli/installer | bash
      - export PATH="$HOME/.symfony/bin:$PATH"
      - symfony security:check

pipelines:
  custom:
    security: 
      - step: *security # Check for Known Security Vulnerabilities in Your Dependencies
         
    test: # Pipeline Test to test only a specific branch
      - step: *composer
      - step: *test
          
    deploy-test2: # Pipeline to deploy auf Test Environment. This can run for every selected branch
      - step: *composer
      - step: *test
      - step: *build
      - step: 
          <<: *deploy
          trigger: manual
          deployment: test
          
    deploy-productions: # Pipeline to deploy auf Production Environment. This can run for every selected branch
      - step: *composer
      - step: *test
      - step: *build
      - step:
          <<: *deploy
          trigger: manual
          deployment: production
      
  branches:
    test:   
      - step: *composer
      - step: *test
      - step: *build
      - step: 
          <<: *deploy
          trigger: manual
          deployment: test
          
  tags:
    v-*:   # On every commit of Tag  run steps and deploy production is triggered manually
      - step: *composer
      - step: *test
      - step: *build
      - step: 
          <<: *deploy
          trigger: manual
          deployment: production
      

```
Create an IAM User with Permissions S3FullAccess and BeanstalkFullAccess and use the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY for the deployment process
