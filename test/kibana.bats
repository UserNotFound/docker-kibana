#!/usr/bin/env bats

source /tmp/test/shared.sh

teardown() {
  cleanup
}

@test "kibana-security detects supported Elasticsearch for kibana-security:${KIBANA_VERSION}" {
  echo '{"version": {"number": "'"${KIBANA_VERSION}"'"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  /bin/bash check-es-version.sh http://localhost:456
}

@test "kibana-security detects incompatible Elasticsearch versions" {
  echo '{"version": {"number": "6.8.1"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  run /bin/bash check-es-version.sh http://localhost:456
  [ $(expr "$output" : ".*using the right image: aptible/kibana:6.8") -ne 0 ]
}

@test "It should install Kibana $KIBANA_VERSION" {
  run /opt/kibana/bin/kibana --allow-root --version
  [[ "$output" =~ "$KIBANA_VERSION"  ]]
}

@test "docker-kibana requires the AUTH_CREDENTIALS environment variable to be set" {
  skip "Perhaps warn _if_ it's provided, since it won't be used."
  export DATABASE_URL=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "AUTH_CREDENTIALS" ]]
}

@test "docker-kibana requires the DATABASE_URL environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "DATABASE_URL" ]]
}

@test "docker-kibana redirects any http requests permanently to https" {
  skip "Should we keep nginx _just_ for this?"
  DATABASE_URL=http://localhost timeout 1 /bin/bash run-kibana.sh || true
  REDIRECT_301="301 Moved Permanently"
  run bash -c 'curl http://localhost | grep "$REDIRECT_301" && \
               curl http://localhost/_aliases | grep "$REDIRECT_301" && \
               curl http://localhost/foo/_aliases | grep "$REDIRECT_301" && \
               curl http://localhost/_nodes | grep "$REDIRECT_301" && \
               curl http://localhost/foobar/_search | grep "$REDIRECT_301" && \
               curl http://localhost/foobar/_mapping | grep "$REDIRECT_301" && \
               curl http://localhost/kibana-int/dashboard/foo | grep "$REDIRECT_301" && \
               curl http://localhost/kibana-int/tempfoo | grep "$REDIRECT_301"'
  [ "$status" -eq 0 ]
}

@test "docker-kibana protects all pages with basic auth" {
  skip "Not anymore, bub."
  XFP="X-Forwarded-Proto: https"
  ERROR_401="401 Authorization Required"
  DATABASE_URL=http://localhost timeout 1 /bin/bash run-kibana.sh || true
  run bash -c 'curl -H "$XFP" http://localhost | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/_aliases | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foo/_aliases | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/_nodes | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foobar/_search | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foobar/_mapping | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/kibana-int/dashboard/foo | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/kibana-int/tempfoo | grep "$ERROR_401"'
  [ "$status" -eq 0 ]
}

ES_URL_KEY=elasticsearch.hosts
ES_USERNAME_KEY=elasticsearch.username
ES_PASSWORD_KEY=elasticsearch.password

@test "docker-kibana sets the elasticsearch url correctly" {
  DATABASE_URL=http://root:admin123@localhost:1234 timeout 1 /bin/bash run-kibana.sh || true
  run grep "${ES_URL_KEY}: \"http://root:admin123@localhost:1234\"" "opt/kibana/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch username correctly" {
 DATABASE_URL=http://root:admin123@localhost:1234 timeout 1 /bin/bash run-kibana.sh || true
 run grep "${ES_USERNAME_KEY}: \"root\"" "opt/kibana/config/kibana.yml"
 [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch password correctly" {
  DATABASE_URL=http://root:admin123@localhost:1234 timeout 1 /bin/bash run-kibana.sh || true
  run grep "${ES_PASSWORD_KEY}: \"admin123\"" "opt/kibana/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "docker-kibana detects unsupported Elasticsearch versions" {
  echo '{"version": {"number": "0.8"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  run /bin/bash check-es-version.sh http://localhost:456
  [ $(expr "$output" :  ".*supported Elasticsearch server") -ne 0 ]
}

@test "docker-kibana detects inability to connect to Elasticsearch" {
  run /bin/bash check-es-version.sh http://localhost:456
  [ $(expr "$output" : ".*Unable to reach Elasticsearch server") -ne 0 ]
}
