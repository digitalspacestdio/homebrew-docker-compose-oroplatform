# OroCommerce Development Environment



## Pre-requirements on (MacOs only)
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

Clone this repo
```bash
git clone git@github.com:digitalspacestdio/docker-orocommerce-dev.git
```

Go to the working dir
```bash
cd docker-orocommerce-dev
```

Put your code to the `www` folder
```bash
git clone --single-branch --branch 4.2.7 git@github.com:oroinc/orocommerce-application.git www
```

Export your composer auth tokens
If you use github only
```bash
export COMPOSER_AUTH='{"github-oauth": {"github.com": "xxxxxxxxxxxx"}}'
````

If you use github and gitlab
```bash
export COMPOSER_AUTH='{"github-oauth": {"github.com": "xxxxxxxxxxxx"}, "gitlab-token": {"example.org": "xxxxxxxxxxxx"}}'
```

Start the stack
```bash
./docker-compose-wrapper up
```

Start the stack in the detached mode
```bash
./docker-compose-wrapper up -d
```

Start use specific php version just export environment variable:
```bash
export PHP_VERSION=7.4
```

Install dependencies
```bash
./docker-compose-wrapper run --rm cli composer install -o --no-interaction
```

Install the application
```bash
./docker-compose-wrapper run --rm cli bin/console --timeout=900 oro:install --language=en --formatting-code=en_US --organization-name='Acme Inc.'  --user-name=admin --user-email=admin@example.com --user-firstname=John --user-lastname=Doe --user-password='$ecretPassw0rd' --application-url='http://localhost:8000/' --sample-data=y
```

Stop the stack
```bash
./docker-compose-wrapper down
```

Destroy the whole data
```bash
./docker-compose-wrapper down -v
```
