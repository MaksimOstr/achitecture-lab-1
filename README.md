# mywebapp

## CI/CD

Automated pipeline: lint → test (≥40% coverage) → build Docker image → deploy → verify.

## Documentation

This repository contains the implementation and documentation for the laboratory assignment on automated deployment of a web application to Ubuntu/WSL.

Additional deployment details:

- [docs/deployment.md](C:/Users/Admin/Desktop/architecture-lab1/docs/deployment.md)

## Individual Assignment Variant

Initial value:

- `N = 21`

Calculations:

- `V2 = (21 % 2) + 1 = 2`
- `V3 = (21 % 3) + 1 = 1`
- `V5 = (21 % 5) + 1 = 2`

Individual assignment:

- application: `Notes Service`
- configuration mode: external file `/etc/mywebapp/config.yaml`
- database: `PostgreSQL`
- application port by variant: `5200`

## Application Purpose

`mywebapp` is a simple notes web application. It stores data in `PostgreSQL` and returns responses in either `application/json` or `text/html` depending on the `Accept` header.

Main features:

- list notes
- create a note
- get a single note by `id`
- check application health through health endpoints

Note fields:

- `id`
- `title`
- `content`
- `created_at`

## Web Application Documentation

Implemented endpoints:

- `GET /`
- `GET /health/alive`
- `GET /health/ready`
- `GET /notes`
- `POST /notes`
- `GET /notes/{id}`

OpenAPI/Swagger:

- Swagger UI: `http://127.0.0.1:5200/swagger-ui.html`
- OpenAPI JSON: `http://127.0.0.1:5200/v3/api-docs`

Database migration:

- [src/main/resources/db/migration/V1__create_notes.sql](C:/Users/Admin/Desktop/architecture-lab1/src/main/resources/db/migration/V1__create_notes.sql)

External configuration for the deployed system:

- `/etc/mywebapp/config.yaml`
- template: [deploy/templates/config.yaml](C:/Users/Admin/Desktop/architecture-lab1/deploy/templates/config.yaml)

## Development, Testing, and Runtime Environment Setup

Requirements:

- `Java 21`
- `PostgreSQL`
- a Unix-like environment to run `./gradlew`

For full containerized startup required by Laboratory Work No. 2, the repository includes:

- [docker-compose.yml](C:/Users/Admin/Desktop/architecture-lab1/docker-compose.yml)

Start the full stack:

```powershell
docker compose up -d --build
```

Services started by compose:

- `postgres`
- `web`
- `nginx`

Compose runtime addresses:

- `http://127.0.0.1/` through `nginx`
- `http://127.0.0.1/swagger-ui.html` through `nginx`

The compose stack uses:

- a dedicated Docker network: `mywebapp-net`
- a persistent Docker volume: `postgres-data`

Build the application:

```bash
./gradlew bootJar
```

Run tests:

```bash
./gradlew test
```

Run the application locally:

```bash
./gradlew bootRun
```

Local application address:

- `http://127.0.0.1:5200`

## Docker Compose Run

Build and start the full system:

```powershell
docker compose up -d --build
```

Build only the optimized multi-stage backend image:

```powershell
docker build -t mywebapp:multistage -f Dockerfile .
```

Build the comparison single-stage backend image:

```powershell
docker build -t mywebapp:single-stage -f Dockerfile.single-stage .
```

Compare image sizes:

```powershell
docker images mywebapp
```

Stop the system:

```powershell
docker compose down
```

Stop the system and remove the database volume:

```powershell
docker compose down -v
```

Check container status:

```powershell
docker compose ps
```

Check logs:

```powershell
docker compose logs -f
```

After startup, verify:

```powershell
curl.exe -i http://127.0.0.1/
curl.exe -i -H "Accept: application/json" http://127.0.0.1/notes
curl.exe -i http://127.0.0.1/swagger-ui.html
```

## How To Run The Developed Web Application

For local execution:

1. Start PostgreSQL.
2. Make sure the application configuration is available.
3. Run:

```bash
./gradlew bootRun
```

After startup, the following URLs should be available:

- `http://127.0.0.1:5200/`
- `http://127.0.0.1:5200/swagger-ui.html`
- `http://127.0.0.1:5200/v3/api-docs`

## API Endpoint Documentation

### `GET /`

- response type: `text/html`
- returns an HTML page with the list of main endpoints

### `GET /health/alive`

- purpose: checks that the application process is running
- response: `200 OK`
- body: `OK`

### `GET /health/ready`

- purpose: checks that the application is ready to work with the database
- response: `200 OK` when the database connection is available
- response: `500` when the application is not ready

### `GET /notes`

- supports `Accept: application/json`
- supports `Accept: text/html`
- for `application/json`, returns an array of objects with `id` and `title`
- for `text/html`, returns an HTML table with notes

Example:

```bash
curl -i -H 'Accept: application/json' http://127.0.0.1:5200/notes
```

### `POST /notes`

- accepts `application/json`
- accepts `application/x-www-form-urlencoded`
- fields:
  - `title`
  - `content`
- for `Accept: application/json`, returns the created note as JSON
- for `Accept: text/html`, returns the created note as HTML
- expected status: `201 Created`

Example JSON request:

```bash
curl -X POST http://127.0.0.1:5200/notes \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"title":"Lab","content":"First note"}'
```

### `GET /notes/{id}`

- supports `Accept: application/json`
- supports `Accept: text/html`
- for `application/json`, returns `id`, `title`, `content`, `createdAt`
- for `text/html`, returns an HTML page with note details

Example:

```bash
curl -i -H 'Accept: application/json' http://127.0.0.1:5200/notes/1
```

## Deployment Documentation

Main deployment automation script:

- [scripts/install-vm.sh](C:/Users/Admin/Desktop/architecture-lab1/scripts/install-vm.sh)

### Base Virtual Machine Image

The deployment must use an official image:

- `Ubuntu Server 24.04 LTS`

Source:

- the official Ubuntu website for a regular VM
- the official `Ubuntu` distribution for `WSL`

Which image to download:

- for VirtualBox, VMware, or Hyper-V: the official `Ubuntu Server 24.04 LTS` image
- for Windows Subsystem for Linux: the official `Ubuntu` distribution

### Virtual Machine Resource Requirements

Recommended minimum:

- CPU: `2 vCPU`
- RAM: `4 GB`
- Disk: `20 GB`

### How To Log In To The VM And Which Credentials To Use

Supported login methods:

- `Console`
- `SSH`

For a regular Ubuntu VM:

- log in with the default user created during Ubuntu installation
- credentials are defined during OS installation

For WSL:

- open Windows PowerShell
- run `wsl -d Ubuntu`

After `install-vm.sh` finishes, the default user must be blocked, and login should be performed only with one of these users:

- `student`
- `teacher`
- `operator`

Initial password set by the script for these users:

- `12345678`

On first login, the system forces a password change.

For WSL, after deployment the default login user becomes `student` instead of `root`.

### How To Download And Run The Deployment Automation

1. Get the repository code.
2. Open the Ubuntu VM or WSL.
3. Go to the repository directory.
4. Run the script:

```bash
cd /mnt/c/Users/Admin/Desktop/architecture-lab1
sudo DEFAULT_VM_USER= MYWEBAPP_DB_PASSWORD=mywebapp ./scripts/install-vm.sh
```

What the script does:

- in WSL, copies the repository from `/mnt/...` into the Linux filesystem
- installs `sudo`, `Java 21`, `PostgreSQL`, `Nginx`, `curl`, `unzip`, and `netcat`
- creates users `student`, `teacher`, `operator`, and `mywebapp`
- adds `student` and `teacher` to the `sudo` group
- creates the `mywebapp` database and the `mywebapp` database user
- builds the application with `./gradlew bootJar`
- installs `systemd` unit files
- configures `Nginx`
- enables socket activation
- creates `/home/student/gradebook` with the value `21`
- locks the original default user if it is not `student`, `teacher`, or `operator`
- locks `root`
- for WSL, writes `/etc/wsl.conf` so that `student` becomes the default user

For WSL, after the script finishes, restart the distribution from Windows PowerShell:

```powershell
wsl --shutdown
```

After the next `wsl -d Ubuntu` start, the session should open as `student`.

### Deployed Runtime Layout

- `Nginx`: `0.0.0.0:80`
- `PostgreSQL`: `127.0.0.1` on the local PostgreSQL port configured by the system
- `mywebapp.socket`: `127.0.0.1:5200`
- Spring Boot backend: `127.0.0.1:15200`

## Deployed System Testing Instructions

The following commands were used to verify that the deployed system was configured correctly.

Check services:

```bash
systemctl status mywebapp-backend.service mywebapp.socket mywebapp.service nginx postgresql --no-pager
```

Check listening ports:

```bash
ss -ltnp | egrep '(:80|:5200|:15200|:5432|:5433)'
```

Check the main page and business endpoints:

```bash
curl -i http://127.0.0.1/
curl -i -H 'Accept: application/json' http://127.0.0.1/notes
curl -i -X POST http://127.0.0.1/notes \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"title":"Lab","content":"First note"}'
curl -i -H 'Accept: application/json' http://127.0.0.1/notes/1
curl -i http://127.0.0.1:15200/health/alive
curl -i http://127.0.0.1:15200/health/ready
```

Check that `/health/alive` is not exposed through external `Nginx`:

```bash
curl -i http://127.0.0.1/health/alive
```

Expected result:

- the main page is available through `Nginx`
- `GET /notes` works
- note creation works
- `GET /notes/{id}` works
- internal health endpoints are available on the backend port
- `/health/alive` must not be available through external port `80`

Check the gradebook:

```bash
cat /home/student/gradebook
```

Expected result:

- the file contains only the value `21`

Check users:

```bash
id student
id teacher
id operator
id mywebapp
```

Check operator restrictions:

```bash
sudo -l -U operator
```

Check that the default user and `root` are locked:

```bash
passwd -S root
grep '^root:' /etc/shadow
```

For WSL, verify that the default user is now `student`:

```powershell
wsl --shutdown
wsl -d Ubuntu
```

After login:

```bash
whoami
```

Expected result:

- the command returns `student`

## Repository Structure

- [src](C:/Users/Admin/Desktop/architecture-lab1/src)
- [scripts](C:/Users/Admin/Desktop/architecture-lab1/scripts)
- [deploy](C:/Users/Admin/Desktop/architecture-lab1/deploy)
- [docs](C:/Users/Admin/Desktop/architecture-lab1/docs)
