# OroCommerce Development Environment

Put your code to the `www` folder
```bash
git clone git@github.com:oroinc/orocommerce-application.git www
```

```bash
export COMPOSER_AUTH={"github-oauth": {"github.com": "xxxxxxxxxxxx"}}
```

Build the stack
```bash
docker-compose build
```

Start the stack
```bash
docker-compose up
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
