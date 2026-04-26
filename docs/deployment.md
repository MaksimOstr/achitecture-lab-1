# Deployment

## Goal

Deploy `mywebapp` on Ubuntu in WSL with one command from the repository.

Main deploy script:

- [scripts/install-vm.sh](C:/Users/Admin/Desktop/architecture-lab1/scripts/install-vm.sh)

## Ubuntu Installation In WSL

Open Windows PowerShell as Administrator and run:

```powershell
wsl --shutdown
wsl --unregister Ubuntu
wsl --install Ubuntu --no-launch
& 'C:\Program Files\WindowsApps\CanonicalGroupLimited.Ubuntu_2404.1.68.0_x64__79rhkp1fndgsc\ubuntu.exe' install --root
```

Check that Ubuntu exists:

```powershell
wsl -l -v
```

You should see `Ubuntu` in the list.

Then open Ubuntu:

```powershell
wsl -d Ubuntu
```

## Deployment

Inside Ubuntu run:

```bash
cd /mnt/c/Users/Admin/Desktop/architecture-lab1
sudo DEFAULT_VM_USER= MYWEBAPP_DB_PASSWORD=mywebapp ./scripts/install-vm.sh
```

What the script does:

- in WSL, copies the project into the Linux filesystem automatically
- installs Java, PostgreSQL, and Nginx
- creates Linux users
- runs the backend as Linux user `mywebapp`
- creates the PostgreSQL database
- installs `systemd` services
- configures Nginx
- runs migration
- starts the application
- creates `/home/student/gradebook`

Wait until the script prints:

```text
Deployment completed.
```

## Open The App

In Windows browser open:

```text
http://127.0.0.1/
```

## Basic Check Commands

Check services:

```bash
systemctl status mywebapp-backend.service mywebapp.socket mywebapp.service nginx postgresql --no-pager
```

List running services:

```bash
systemctl list-units --type=service --state=running
```

Check ports:

```bash
ss -ltnp | egrep '(:80|:5432|:5200|:15200)'
```

Check app:

```bash
curl -i http://127.0.0.1/
curl -i -H 'Accept: application/json' http://127.0.0.1/notes
curl -i http://127.0.0.1:15200/health/alive
cat /home/student/gradebook
```

Check gradebook number only:

```bash
cat /home/student/gradebook
```

Check that the default user is locked:

```bash
sudo passwd -S root
sudo grep '^root:' /etc/shadow
```

Expected:

- `ubuntu L ...` in `passwd -S` output means the user is locked
- password field starting with `!` in `/etc/shadow` means the user is locked

If the default user is `root`, use:

```bash
passwd -S root
grep '^root:' /etc/shadow
```

Expected:

- `root L ...` in `passwd -S` output means the user is locked
- password field starting with `!` in `/etc/shadow` means the user is locked

Check that created users exist:

```bash
id student
id teacher
id operator
id mywebapp
```

Check that you can switch to created users:

```bash
su - student
whoami
exit

su - teacher
whoami
exit

su - operator
whoami
exit
```

## Basic Service Commands

Stop app:

```bash
sudo systemctl stop mywebapp.socket mywebapp.service mywebapp-backend.service
```

Start app:

```bash
sudo systemctl start mywebapp-backend.service
sudo systemctl start mywebapp.socket
```

Restart app:

```bash
sudo systemctl restart mywebapp-backend.service
sudo systemctl restart mywebapp.socket
```

Check logs:

```bash
journalctl -u mywebapp-backend.service -n 100 --no-pager
journalctl -u nginx -n 100 --no-pager
```
