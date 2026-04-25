#!/usr/bin/env bash
set -euo pipefail

jar="$(find "$(dirname "$0")/../build/libs" -maxdepth 1 -name 'mywebapp*.jar' | head -n 1)"

if [[ -z "${jar}" ]]; then
  echo "Build the application first with ./gradlew bootJar" >&2
  exit 1
fi

java -jar "$jar" --spring.config.additional-location=file:/etc/mywebapp/config.yaml --spring.main.web-application-type=none --mywebapp.migrate-only=true
