# Deploying The-Board behind IIS

Complete guide for deploying The-Board (Node.js + PostgreSQL ticket management system) on a Windows Server that already has IIS installed and a working TLS-bound site.

## Architecture

```
Browser ──HTTPS:443──▶ IIS (TLS termination)
                       │  URL Rewrite + ARR (reverse proxy)
                       ▼
                   http://127.0.0.1:3001  ◀── Node app container
                                              │ (internal Docker network)
                                              ▼
                                          Postgres container
```

IIS is the only thing on the public network. The Node container binds to `127.0.0.1:3001` on the host, so it can't be reached from outside the server — only IIS can talk to it. Postgres is bound the same way (`127.0.0.1:5432`): the app reaches it over Docker's internal network, and admin tools (pgAdmin, psql) on the Windows server can connect to it for debugging, but it's never exposed to the LAN or internet.

---

## Prerequisites

- Windows Server 2019 / 2022 (or Windows 10/11 Pro for testing)
- IIS already installed with a site bound to port 443 and a working TLS certificate
- Administrator access to the server
- A copy of this repository on the server

---

## Part 1 — Install WSL2

WSL2 (Windows Subsystem for Linux 2) is required because the containers in this project are Linux-based (`node:20-alpine`, `postgres:16-alpine`).

### 1.1 Install WSL

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This single command will:
- Enable the "Windows Subsystem for Linux" optional feature
- Enable the "Virtual Machine Platform" optional feature
- Download and install the WSL2 Linux kernel
- Install Ubuntu as the default distribution

**Reboot when prompted.**

### 1.2 Verify WSL2 is the default version

After reboot, open PowerShell again and run:

```powershell
wsl --set-default-version 2
wsl --status
```

You should see `Default Version: 2`. If you see version 1, update WSL:

```powershell
wsl --update
```

### 1.3 Confirm Ubuntu launched

After install, Ubuntu will open a terminal window asking you to set a UNIX username and password. Set them and close the window — you don't need to use Ubuntu directly, Docker just needs WSL2 available as a backend.

---

## Part 2 — Install Docker Desktop

> **Licensing note:** Docker Desktop is free for personal use, education, and small businesses (under 250 employees AND under $10M revenue). Larger organizations need a paid subscription. If that's a problem, see the "Alternative: Docker Engine without Desktop" appendix at the bottom.

### 2.1 Download Docker Desktop

Go to https://www.docker.com/products/docker-desktop/ and download **Docker Desktop for Windows**.

### 2.2 Run the installer

1. Double-click `Docker Desktop Installer.exe`.
2. On the configuration screen, ensure **"Use WSL 2 instead of Hyper-V"** is **checked**.
3. Click **OK** and let it install.
4. Reboot when prompted.

### 2.3 First launch

1. Launch Docker Desktop from the Start menu.
2. Accept the service agreement.
3. You can skip the sign-in / survey screens.
4. Wait for the Docker whale icon in the system tray to stop animating — it should say "Docker Desktop is running".

### 2.4 Verify Docker works

Open PowerShell and run:

```powershell
docker --version
docker compose version
docker run --rm hello-world
```

The last command pulls and runs a tiny test container. If it prints "Hello from Docker!", you're good.

### 2.5 Make Docker start with Windows

Docker Desktop → Settings (gear icon) → **General** → check **"Start Docker Desktop when you sign in to your computer"**.

---

## Part 3 — Install the IIS reverse proxy modules

These two modules turn IIS into a reverse proxy. Install order matters: URL Rewrite first.

### 3.1 Install URL Rewrite 2.1

Download from https://www.iis.net/downloads/microsoft/url-rewrite and run the MSI. Accept defaults.

### 3.2 Install Application Request Routing 3.0

Download from https://www.iis.net/downloads/microsoft/application-request-routing (or the [Microsoft Download Center x64 link](https://www.microsoft.com/en-us/download/details.aspx?id=47333)) and run the MSI. Accept defaults.

### 3.3 Verify in IIS Manager

Open **IIS Manager** (`inetmgr.exe`). Click your server node at the top of the left tree. In the center pane (Features View), you should now see two new icons:

- **URL Rewrite**
- **Application Request Routing Cache**
- **Application Request Routing** (the proxy feature itself)

If they're missing, restart IIS (`iisreset` in an elevated PowerShell) and check again.

---

## Part 4 — Enable the ARR reverse proxy (one-time, server-wide)

By default, ARR is installed but proxying is **off**. Turn it on:

1. In IIS Manager, click the **server node** at the top of the left tree.
2. In the center pane, double-click **Application Request Routing** (the feature itself, *not* "Application Request Routing Cache").
3. In the right-hand Actions pane, click **Server Proxy Settings…** (or look for the "Enable Proxy" checkbox directly on the page).
4. Check **Enable proxy**.
5. Click **Apply**.

Without this step, every URL Rewrite rule that points to an external URL will silently fail.

---

## Part 5 — Whitelist forwarded headers (one-time, per site)

The `web.config` we'll add in Part 6 sets two custom headers (`X-Forwarded-Proto`, `X-Forwarded-Host`) so the Node app knows the original request was HTTPS and what hostname the user typed. IIS blocks setting these by default — you have to whitelist them first or you'll get a **500.50** error on every request.

1. In IIS Manager, select your site (e.g. **Default Web Site**) in the left tree.
2. Double-click the **URL Rewrite** feature.
3. In the right-hand Actions pane, click **View Server Variables…**
4. Click **Add…** and add these (one at a time):
   - `HTTP_X_FORWARDED_PROTO`
   - `HTTP_X_FORWARDED_HOST`
5. Click **Back to Rules** when done.

(`X-Forwarded-For` is added automatically by ARR, so it doesn't need a whitelist entry or a manual `<set>`.)

---

## Part 6 — Configure the IIS site

Drop a `web.config` at the root of the IIS site's physical path (typically `C:\inetpub\wwwroot\web.config`, but check IIS Manager → your site → Basic Settings to confirm).

If a `web.config` already exists, merge the `<rewrite>` block into the existing `<system.webServer>` element rather than overwriting the whole file.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="ReverseProxyToNode" stopProcessing="true">
          <match url="(.*)" />
          <action type="Rewrite" url="http://localhost:3001/{R:1}" />
          <serverVariables>
            <set name="HTTP_X_FORWARDED_PROTO" value="https" />
            <set name="HTTP_X_FORWARDED_HOST" value="{HTTP_HOST}" />
          </serverVariables>
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
```

What this does:
- **`<match url="(.*)" />`** — matches every request path.
- **`<action type="Rewrite" url="http://localhost:3001/{R:1}" />`** — forwards the request to the Node container, preserving the original path (`{R:1}` is the captured `(.*)`).
- **`stopProcessing="true"`** — short-circuits any other rules so this is the only thing that runs.
- **`<serverVariables>`** — tells the backend that the original protocol was HTTPS and what hostname was used.

### 6.1 (Optional) Preserve the original Host header

By default, ARR rewrites the `Host` header on the way to Node, so Node sees `Host: localhost:3001`. If your app ever needs the original public hostname (for absolute-URL generation, OAuth callbacks, cookie domains, etc.), enable host preservation:

1. IIS Manager → server node → **Configuration Editor**.
2. Section dropdown at the top: `system.webServer/proxy`.
3. Find **`preserveHostHeader`** and set it to `True`.
4. Click **Apply**.

The current ticket app doesn't need this.

---

## Part 7 — Bring up the containers

Copy the project folder onto the server (e.g. `C:\apps\The-Board`). Open PowerShell **in that folder** and run:

```powershell
docker compose up -d --build
```

This will:
1. Pull `postgres:16-alpine` and `node:20-alpine` images (first run only — takes a few minutes).
2. Build the app image from the included `Dockerfile`.
3. Start Postgres, wait for it to be healthy.
4. Start the Node app, which connects to Postgres over the internal Docker network.

### 7.1 Verify containers are running

```powershell
docker compose ps
```

Both services should show **running** / **healthy**. If `app` exited, look at logs:

```powershell
docker compose logs app
docker compose logs db
```

### 7.2 Verify the Node app responds locally

From the server itself:

```powershell
curl http://localhost:3001/
```

You should get HTML or JSON back from the app.

---

## Part 8 — Test end-to-end

From any browser, hit `https://yourdomain/`.

The flow:
1. Browser → IIS:443 (TLS terminates here).
2. URL Rewrite matches the request, ARR forwards to `http://localhost:3001/`.
3. Node container handles the request, queries Postgres over the Docker network.
4. Response flows back through ARR → IIS → browser.

If it works — you're deployed.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| **502 Bad Gateway** from IIS | Node container not running, or ARR proxy not enabled | `docker compose ps`; verify Part 4 |
| **500.50** on first request | A `<serverVariables>` entry isn't whitelisted | Re-do Part 5 for the site hosting `web.config` |
| **404** on subpaths but `/` works | Another rewrite rule is intercepting | Confirm `stopProcessing="true"` and no rules sit above this one |
| Page loads but assets/links broken | App generating absolute URLs with `localhost:3001` | Enable `preserveHostHeader` (Part 6.1) |
| Containers don't restart after server reboot | Missing `restart:` policy | Confirm `restart: unless-stopped` on both services in `docker-compose.yml` |
| `docker compose up` fails with "WSL 2 not installed" | WSL2 backend not enabled | Re-run Part 1; in Docker Desktop → Settings → General, ensure "Use WSL 2 based engine" is checked |
| Slow performance / high CPU on first request | Cold container | Normal; subsequent requests are fast |

### Looking deeper

- **Node logs:** `docker compose logs -f app`
- **Postgres logs:** `docker compose logs -f db`
- **IIS Failed Request Tracing:** IIS Manager → site → Failed Request Tracing Rules. Useful for seeing whether ARR even attempted the proxy.
- **IIS access logs:** `C:\inetpub\logs\LogFiles\W3SVC<n>\` — confirms requests are arriving at IIS.

---

## Updating the app

When you push new code, on the server:

```powershell
cd C:\apps\The-Board
git pull
docker compose up -d --build
```

ARR keeps proxying through the rebuild — IIS will return a brief 502 during the container restart (~2–5 seconds), then automatically recover.

To stop everything:

```powershell
docker compose down
```

To stop everything **and wipe the database** (destructive):

```powershell
docker compose down -v
```

---

## Backups

Postgres data lives in a Docker volume named `the-board_db-data` (Docker prefixes with the project folder name). To back it up:

```powershell
docker compose exec db pg_dump -U postgres board > backup-$(Get-Date -Format "yyyyMMdd").sql
```

To restore into a fresh stack:

```powershell
docker compose down -v
docker compose up -d db
docker compose exec -T db psql -U postgres -d board < backup-20260101.sql
docker compose up -d app
```

---

## Appendix: Alternative — Docker Engine without Desktop (no licensing)

If Docker Desktop's licensing doesn't fit (large org, no subscription) and you'd rather avoid it on a production server, you can install **Docker Engine** directly inside WSL2:

1. Install WSL2 + Ubuntu as in Part 1.
2. Open the Ubuntu terminal and follow Docker's official install steps for Ubuntu: https://docs.docker.com/engine/install/ubuntu/
3. Run `docker compose` commands from inside the WSL2 Ubuntu shell instead of Windows PowerShell.
4. The project folder is accessible from WSL at `/mnt/c/apps/The-Board/`.

The IIS side is identical — IIS still talks to `http://localhost:3001` and WSL2 forwards localhost ports to Windows automatically.

---

## Checklist (TL;DR)

- [ ] WSL2 installed (`wsl --install`)
- [ ] Docker Desktop installed and running
- [ ] URL Rewrite 2.1 installed in IIS
- [ ] ARR 3.0 installed in IIS
- [ ] ARR proxy enabled (server node → Application Request Routing → Enable proxy)
- [ ] `HTTP_X_FORWARDED_PROTO` and `HTTP_X_FORWARDED_HOST` whitelisted on the site
- [ ] `web.config` deployed with the rewrite rule
- [ ] Project folder copied to server, `docker compose up -d --build` succeeds
- [ ] `curl http://localhost:3001/` returns the app
- [ ] `https://yourdomain/` loads the app end-to-end
