# OroCommerce|OroCRM|OroPlatform Docker Environment

## Pre-requirements (MacOs only)
Configure and start nfs
```bash
echo "$HOME -alldirs -mapall=$UID:20 localhost" | sudo tee -a /etc/exports
echo "nfs.server.mount.require_resv_port = 0" | sudo tee -a /etc/nfs.conf
```

Start the NFS server
```bash
sudo nfsd restart
```

## Usage

Export your composer auth tokens
If you use github only
```bash
export COMPOSER_AUTH='{"github-oauth": {"github.com": "xxxxxxxxxxxx"}}'
````

If you use github and gitlab
```bash
export COMPOSER_AUTH='{"github-oauth": {"github.com": "xxxxxxxxxxxx"}, "gitlab-token": {"example.org": "xxxxxxxxxxxx"}}'
```

To use specific php version just export environment variable:
```bash
export PHP_VERSION=7.4
```
> following versions are supported: 7.2, 7.3, 7.4, 8.0

Clone this repo
```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

Go to the working dir
```bash
cd docker-env-oroplatform
```

Put your code to the `www` folder
```bash
git clone --single-branch --branch 4.2.7 git@github.com:oroinc/orocommerce-application.git www
```

Create the `.env` file
```bash
# if you want to use mysql
cp .env.dist.mysql .env

# if you want to use postgresql
cp .env.dist.pgsql .env
```

Install dependencies
```bash
docker-compose-oroplatform run --rm cli composer install -o --no-interaction
```

Install the application
```bash
docker-compose-oroplatform run --rm cli bin/console --env=prod --timeout=1800 oro:install --language=en --formatting-code=en_US --organization-name='Acme Inc.'  --user-name=admin --user-email=admin@example.com --user-firstname=John --user-lastname=Doe --user-password='$ecretPassw0rd' --application-url='http://localhost:30180/' --sample-data=y
```

Start the stack
```bash
docker-compose-oroplatform up
```

Also you can start the stack in the background mode
```bash
docker-compose-oroplatform up -d
```

> Application should be available by following link: http://localhost:30180/

Stop the stack
```bash
docker-compose-oroplatform down
```

Destroy the whole data
```bash
docker-compose-oroplatform down -v
```

## Mutagen Integration

To use mutagen integration just define environment variable
```bash
export COMPOSE_PROJECT_MODE=mutagen
```
