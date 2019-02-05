# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/kibana

Kibana as an Aptible App.

This is an example, unsupported configuration.


## Security considerations
This is an example, unsupported configuration.

This app is configured through two environment variables: `AUTH_CREDENTIALS`
and `DATABASE_URL`. The former is used to authenticate Kibana users, and the
latter is used to make requests to a backend Elasticsearch instance.

In other words, **any user that can log in to Kibana can execute queries
against the upstream Elasticsearch instance using Kibana's credentials**.

This is probably what you want if you're deploying Kibana, but it means you
should make sure you choose strong passwords for `AUTH_CREDENTIALS`.

## Installation

This is an example, unsupported configuration.

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2014 [Aptible](https://www.aptible.com) and contributors.

[<img src="https://s.gravatar.com/avatar/c386daf18778552e0d2f2442fd82144d?s=60" style="border-radius: 50%;" alt="@aaw" />](https://github.com/aaw)
