#!/bin/bash
#shellcheck disable=SC2086
set -o errexit
set -o nounset
set -o pipefail

function echo_with_banner() {
  echo "."
  echo "."
  echo "###########################"
  echo "#"
  echo "# ERROR - READ THIS MESSAGE"
  echo "#"
  echo "#"

  for message in "$@"; do
    echo "# > $message"
  done
  echo "#"

  echo "#"
  echo "# END OF ERROR"
  echo "#"
  echo "###########################"
  echo "."
  echo "."
}

DATABASE_URL="${1:-}"

if [[ -z "$DATABASE_URL" ]]; then
  echo_with_banner "No DATABASE_URL was provided"
  exit 1
fi

function wait_for_request {
  for _ in {1..10}; do
    if curl -f "$DATABASE_URL" > /dev/null 2>&1; then
      return 0
    else
      sleep 1
    fi
  done

  echo_with_banner \
    "Unable to reach Elasticsearch server, please check DATABASE_URL and your database server." \
    "If necessary, correct the URL. Then, deploy again."

  return 1
}


#Check that we're using the right Kibana version for the ES we're connecting to

KIBANA_VERSION_PARSER="
require 'json'
es_version = JSON.parse(STDIN.read)['version']['number']
print 'kibana:4.1' if es_version.start_with?('1.')
print 'kibana:4.4' if es_version.start_with?('2.')
print 'kibana:5.0' if es_version.start_with?('5.0.')
print 'kibana:5.1' if es_version.start_with?('5.1.')
print 'kibana:5.6' if es_version.start_with?('5.6.')
print 'kibana:6.0' if es_version.start_with?('6.0.')
print 'kibana:6.1' if es_version.start_with?('6.1.')
print 'kibana:6.2' if es_version.start_with?('6.2.')
print 'kibana:6.3' if es_version.start_with?('6.3.')
print 'kibana:6.4' if es_version.start_with?('6.4.')
print 'kibana:6.5' if es_version.start_with?('6.5.')
print 'kibana:6.6' if es_version.start_with?('6.6.')
print 'kibana:6.7' if es_version.start_with?('6.7.')
print 'kibana:6.8' if es_version.start_with?('6.8.')
print 'kibana-security:7.0' if es_version.start_with?('7.0.')
print 'kibana-security:7.1' if es_version.start_with?('7.1.')
print 'kibana-security:7.2' if es_version.start_with?('7.2.')
print 'kibana-security:7.3' if es_version.start_with?('7.3.')
print 'kibana-security:7.4' if es_version.start_with?('7.4.')
print 'kibana-security:7.5' if es_version.start_with?('7.5.')"


wait_for_request

KIBANA_NEEDED_VERSION="$(curl -fsSL "$DATABASE_URL" | ruby -e "$KIBANA_VERSION_PARSER")"

if [[ -z "$KIBANA_NEEDED_VERSION" ]]; then
  echo_with_banner \
    "DATABASE_URL does not point at a supported Elasticsearch server."
  exit 1
fi

if [[ "kibana-security:${TAG}" != "$KIBANA_NEEDED_VERSION" ]]; then
  echo_with_banner \
    "Incorrect Kibana version detected!" \
    "You are using aptible/kibana-security:${TAG}, which is not compatible with your version of Elasticsearch." \
    "Deploy again using the right image: aptible/${KIBANA_NEEDED_VERSION}"
  exit 1
fi
