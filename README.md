# OroCommerce Development Environment

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
docker-compose up
```

Start with specific php version:
```bash
PHP_VERSION=7.4 docker-compose up
```

Install dependencies
```bash
docker-compose run cli composer install -o
```

Install the application
```bash
docker-compose run cli bin/console oro:install -vvv
```

Stop the stack
```bash
docker-compose down
```

Destroy the whole data
```bash
docker-compose down -v
```
