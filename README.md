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

Put your code to the `www` folder
```bash
git clone git@github.com:oroinc/orocommerce-application.git www
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

Start with specific php version:
```bash
PHP_VERSION=7.4 docker-compose up
```

Install dependencies
```bash
./docker-compose-wrapper run --rm cli composer install -o
```

Install assets
```bash
./docker-compose-wrapper run --rm cli php bin/console oro:assets:install
```

Install the application
```bash
./docker-compose-wrapper run --rm cli bin/console oro:install -vvv
```

Stop the stack
```bash
./docker-compose-wrapper down
```

Destroy the whole data
```bash
./docker-compose-wrapper down -v
```
