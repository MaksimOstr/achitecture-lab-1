# mywebapp

`N = 21`

`V2 = (21 % 2) + 1 = 2`

`V3 = (21 % 3) + 1 = 1`

`V5 = (21 % 5) + 1 = 2`

Variant:

- Application: Notes Service
- Configuration mode: config file at `/etc/mywebapp/config.yaml`
- Database: PostgreSQL
- Application port: `5200`

## Purpose

`mywebapp` is a simple notes service. It stores notes in PostgreSQL and serves the business API in either `application/json` or `text/html` depending on the `Accept` header.

## Requirements

- Java 21
- Docker Desktop or local PostgreSQL

## Local configuration

The application loads Spring Boot configuration from the repository defaults and additionally from `/etc/mywebapp/config.yaml`.

Example external config:

```yaml
server:
  address: 127.0.0.1
  port: 5200

spring:
  datasource:
    url: jdbc:postgresql://127.0.0.1:5432/mywebapp
    username: mywebapp
    password: mywebapp
```

A copy is included at [config.yaml.example](C:/Users/Admin/Desktop/architecture-lab1/config/config.yaml.example).

## Run

Start PostgreSQL with Docker Compose:

```powershell
docker compose up -d
```

Then run:

```powershell
.\gradlew.bat bootRun
```

The default bind address is `127.0.0.1` and the default port is `5200`.

Swagger UI is available at `http://127.0.0.1:5200/swagger-ui.html`.

OpenAPI JSON is available at `http://127.0.0.1:5200/v3/api-docs`.

## Migration

The schema is managed by Flyway. SQL migration files are in `src/main/resources/db/migration`.

Build the jar:

```powershell
.\gradlew.bat bootJar
```

Run the migration-only command:

```powershell
.\scripts\migrate.ps1
```

The default Docker Compose database already matches the application defaults:

- database: `mywebapp`
- username: `mywebapp`
- password: `mywebapp`
- host: `127.0.0.1`
- port: `5432`

## API

Root endpoint:

- `GET /` returns an HTML page listing the business endpoints.

Health endpoints:

- `GET /health/alive` returns `200 OK` with body `OK`
- `GET /health/ready` returns `200 OK` with body `OK` when PostgreSQL is reachable, otherwise `500`

Business endpoints:

- `GET /notes`
- `POST /notes`
- `GET /notes/{id}`

`GET /notes`

- `Accept: application/json` returns a JSON array of notes with `id` and `title`
- `Accept: text/html` returns an HTML table with `id` and `title`

`POST /notes`

- Accepts `application/json` body with `title` and `content`
- Accepts `application/x-www-form-urlencoded` body with `title` and `content`
- `Accept: application/json` returns the created note as JSON
- `Accept: text/html` returns the created note as HTML

Example:

```powershell
curl -X POST http://127.0.0.1:5200/notes `
  -H "Content-Type: application/json" `
  -H "Accept: application/json" `
  -d '{"title":"Lab","content":"First note"}'
```

`GET /notes/{id}`

- `Accept: application/json` returns `id`, `title`, `content`, `createdAt`
- `Accept: text/html` returns an HTML page with `id`, `title`, `created_at`, `content`
