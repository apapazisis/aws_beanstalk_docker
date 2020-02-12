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
      image: mysql:8.0.16
      environment:
        MYSQL_DATABASE: mydb
        MYSQL_USER: secret
        MYSQL_PASSWORD: secret
        MYSQL_ROOT_PASSWORD: root

  steps:
    - step: &composer
        name: Composer, NPM, Cache
        caches:
          - docker
        image:
          name: "0000000000.dkr.ecr.eu-central-1.amazonaws.com/image:latest"
          aws:
            access-key: $AWS_ECR_ACCESS_KEY_ID
            secret-key: $AWS_ECR_SECRET_ACCESS_KEY
        script:
          - php -v
          - composer -V
          - php -r "file_exists('.env') || copy('.env.example', '.env');"
          - composer install
          - npm install
          - npm run prod
          - php artisan config:clear
          - php artisan config:cache
          - php artisan view:clear
        artifacts:
          - .env
          - vendor/**
          - public/css/**
          - public/fonts/**
          - public/img/**
          - public/js/**
        services:
          - docker

    - step: &test
        name: Test Application
        image:
          name: "0000000000.dkr.ecr.eu-central-1.amazonaws.com/image:latest"
          aws:
            access-key: $AWS_ECR_ACCESS_KEY_ID
            secret-key: $AWS_ECR_SECRET_ACCESS_KEY
        script:
          - echo "Run Tests"
          - vendor/bin/phpunit --testdox
        services:
          - mysql

    - step: &build
        name: Building Application
        image: atlassian/default-image:2
        script:
          - zip -r application.zip * -x .env
        artifacts:
          - application.zip

    - step: &deploy
        name: Deploy to Elasticbeanstalk
        script:
          - pipe: atlassian/aws-elasticbeanstalk-deploy:0.5.5
            variables:
              ENVIRONMENT_NAME: $ENVIRONMENT_NAME
              AWS_ACCESS_KEY_ID: $AWS_DEPLOY_ACCESS_KEY_ID
              AWS_SECRET_ACCESS_KEY: $AWS_DEPLOY_SECRET_ACCESS_KEY
              AWS_DEFAULT_REGION: "eu-central-1"
              APPLICATION_NAME: "example.com"
              ZIP_FILE: "application.zip"
              S3_BUCKET: "s3-example-0000000000"
              VERSION_LABEL: $(date +%d-%m-%Y_%H:%M:%S)_$BITBUCKET_BUILD_NUMBER
          - sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=$DB_CONNECTION/g" .env
          - sed -i "s/DB_HOST=127.0.0.1/DB_HOST=$DB_HOST/g" .env
          - sed -i "s/DB_PORT=3306/DB_PORT=$DB_PORT/g" .env
          - sed -i "s/DB_DATABASE=homestead/DB_DATABASE=$DB_DATABASE/g" .env
          - sed -i "s/DB_USERNAME=homestead/DB_USERNAME=$DB_USERNAME/g" .env
          - sed -i "s/DB_PASSWORD=secret/DB_PASSWORD=$DB_PASSWORD/g" .env
        artifacts:
          - .env

    - step: &migrations
        name: Run Migrations
        image:
          name: "0000000000.dkr.ecr.eu-central-1.amazonaws.com/image:latest"
          aws:
            access-key: $AWS_ECR_ACCESS_KEY_ID
            secret-key: $AWS_ECR_SECRET_ACCESS_KEY
        script:
          - php artisan migrate --force --no-interaction

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

    deploy-stage: # Pipeline to deploy auf Test Environment. This can run for every selected branch
      - step: *composer
      - step: *test
      - step: *build
      - step:
          <<: *deploy
          deployment: stage
      - step:
          <<: *migrations

    deploy-production: # Pipeline to deploy auf Production Environment. This can run for every selected branch
      - step: *composer
      - step: *test
      - step: *build
      - step:
          <<: *deploy
          trigger: manual
          deployment: production
      - step:
          <<: *migrations

  branches:
    stage:
      - step: *composer
      - step: *test
      - step: *build
      - step:
          <<: *deploy
          deployment: stage
      - step: *migrations

  tags:
    v-*:   # On evety commit of Tag  run steps and deploy-production is triggered manually
      - step: *composer
      - step: *test
      - step: *build
      - step:
          <<: *deploy
          trigger: manual
          deployment: production
      - step:
          <<: *migrations

      

```
Create an IAM User with Permissions S3FullAccess and BeanstalkFullAccess and use the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY for the deployment process

### Valid IP addresses for Bitbucket Pipelines build environments

https://confluence.atlassian.com/bitbucket/what-are-the-bitbucket-cloud-ip-addresses-i-should-use-to-configure-my-corporate-firewall-343343385.html

Use this IPs to grant access in your MySQL DB from Bitbucket Pipelines

### Laravel Worker

```
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log
pidfile = /tmp/supervisord.pid

[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work --tries=3 --delay=3
autostart=true
autorestart=true
redirect_stderr=true
numprocs=8
stdout_logfile=/var/log/worker.log

[program:php-fpm]
command=/usr/local/sbin/php-fpm
autostart=true
autorestart=true
```

### Queues with AWS ElasticCache Redis

 - Redis security group should give inbound access to Elastic Beanstalk environment

| Type     |      Protocol      |  Port Range |
|----------|:-------------:|------:|
| Custom TCP Rule |  TCP | 6379 |
