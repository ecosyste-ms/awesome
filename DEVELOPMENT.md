# Development

## Setup

First things first, you'll need to fork and clone the project to your local machine.

`git clone https://github.com/ecosyste-ms/awesome.git`

The project uses ruby on rails which have a number of system dependencies you'll need to install. 

- [ruby 3.3.5](https://www.ruby-lang.org/en/documentation/installation/)
- [postgresql 14](https://www.postgresql.org/download/)
- [redis 6+](https://redis.io/download/)
- [node.js 16+](https://nodejs.org/en/download/)

Once you've got all of those installed, from the root directory of the project run the following commands:

```
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
rails server
```

You can then load up [http://localhost:3000](http://localhost:3000) to access the service.

### Docker

Alternatively you can use the existing docker configuration files to run the app in a container.

Run this command from the root directory of the project to start the service.

`docker-compose up --build`

You can then load up [http://localhost:3000](http://localhost:3000) to access the service.

For access the rails console use the following command:

`docker-compose exec app rails console`

Runing rake tasks in docker follows a similar pattern:

`docker-compose exec app rake projects:sync`

## Importing data

The default set of supported data sources are listed in [db/seeds.rb](db/seeds.rb) and can be automatically enabled with the following rake command:

`rake db:seed`

You can then start syncing data for each source with the following command, this may take a while:

`rake projects:sync`

## Tests

The applications tests can be found in [test](test) and use the testing framework [minitest](https://github.com/minitest/minitest).

You can run all the tests with:

`rails test`

## Rake tasks

The applications rake tasks can be found in [lib/tasks](lib/tasks).

You can list all of the available rake tasks with the following command:

`rake -T`

## Deployment

A container-based deployment is highly recommended, we use [dokku.com](https://dokku.com/).