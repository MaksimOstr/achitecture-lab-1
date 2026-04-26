#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_jar="$(find "$script_dir/../build/libs" -maxdepth 1 -name 'mywebapp*.jar' | head -n 1 || true)"
installed_jar="/opt/mywebapp/current/mywebapp.jar"
jar="${MYWEBAPP_JAR:-}"

if [[ -z "$jar" && -n "$repo_jar" ]]; then
  jar="$repo_jar"
fi

if [[ -z "$jar" && -f "$installed_jar" ]]; then
  jar="$installed_jar"
fi

if [[ -z "${jar}" ]]; then
  echo "Build the application first with ./gradlew bootJar" >&2
  exit 1
fi

java -jar "$jar" \
  --spring.config.additional-location=file:/etc/mywebapp/config.yaml \
  --spring.jpa.hibernate.ddl-auto=none \
  --spring.main.web-application-type=none \
  --mywebapp.migrate-only=true
