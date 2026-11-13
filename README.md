# Banking Branch Office — Linux Server Project

## Project Overview
This project sets up a hardened Linux server for a bank branch supporting
Employees, Managers, and Auditors with secure authentication, encrypted
LVM storage, automated backup, audit log generation, daily audit reports,
and an internal web dashboard.

**Problem Statement #3 — Banking Branch Office (RHCSA Objectives)**

---

## Project Structure

```
banking-branch-server/
├── README.md               ← You are here
├── setup/                  ← One-time setup scripts (run in order)
│   ├── setup.sh            ← Step 1: System config, packages, users, groups
│   ├── lvm_setup.sh        ← Step 2: LVM storage, permissions, firewall
│   ├── cron_setup.sh       ← Step 3: Deploy scripts, cron, SSH hardening
│   ├── new_user.sh         ← Utility: Bulk user creation from CSV
│   ├── users.csv           ← User list for new_user.sh
│   └── ssh_hardening.sh    ← Called by cron_setup.sh automatically
├── scripts/                ← Operational scripts (deployed to /scripts/ on VM)
│   ├── audit_logger.sh     ← Generates audit log entries every minute
│   ├── audit_report.sh     ← Compiles daily audit report at 6:00 PM
│   ├── bank_backup.sh      ← Incremental nightly backup at 11:30 PM
│   └── branch_health.sh    ← Hourly system health monitor
├── website/                ← Internal branch dashboard (deployed to Apache)
│   ├── index.html          ← Landing page
│   ├── employees.html      ← User, group, and permission details
│   ├── audit.html          ← Audit log information
│   ├── reports.html        ← Daily audit report details
│   ├── backup.html         ← Backup schedule and restoration guide
│   ├── security.html       ← Firewall, SSH, and security policy
│   └── cgi-bin/
│       └── status.sh       ← Live server status (auto-refreshes every 30s)
└── docs/
    └── test_all.sh         ← Full automated test suite (57 checks)
```

---

## How to Use

### Step 1 — Copy to your VM
```bash
sudo cp -r banking-branch-server/ /opt/banking/
cd /opt/banking/banking-branch-server
```

### Step 2 — Run setup scripts in order
```bash
# ⚠️ NEVER skip ahead — each step depends on the previous one

sudo bash setup/setup.sh        # System config + users + groups
sudo bash setup/lvm_setup.sh    # LVM storage + permissions + firewall
sudo bash setup/cron_setup.sh   # Scripts + cron jobs + SSH hardening
```

### Step 3 — Deploy the website
```bash
sudo cp -r website/* /var/www/html/
sudo chmod +x /var/www/html/cgi-bin/status.sh
sudo a2enmod cgi && sudo systemctl restart apache2
```

### Step 4 — Run the test suite
```bash
sudo bash docs/test_all.sh
```

### Step 5 — Open the dashboard
```
http://localhost        (inside the VM browser)
http://<server-ip>      (from host machine if Bridged adapter is set)
```

---

## Important Notes Before Running

| # | Note |
|---|------|
| 1 | Run `lsblk` before `lvm_setup.sh` — confirm your second disk is `/dev/sdb` and update the `DISK` variable if different |
| 2 | Change the static IP in `setup/setup.sh` to match your network before running |
| 3 | SSH moves to port **2222** after `cron_setup.sh` — test in a second terminal before closing your session |
| 4 | Add a second 40 GB virtual disk in VirtualBox before running `lvm_setup.sh` |
| 5 | Set VirtualBox network adapter to **Bridged** to access the site from your host browser |
| 6 | All scripts write logs to `/var/logs/branch/` — check there first if anything fails |

---

## Cron Schedule

| Script | Schedule | Purpose |
|--------|----------|---------|
| audit_logger.sh | Every minute | Generates audit log entries |
| audit_report.sh | 6:00 PM daily | Compiles daily audit report |
| branch_health.sh | Every hour | System health snapshot |
| bank_backup.sh | 11:30 PM daily | Incremental backup of reports + audit |

---

## Users & Access

| Username | Group | Role | SSH |
|----------|-------|------|-----|
| emp1, emp2, emp3 | employees | Bank Employee | No |
| mgr1, mgr2 | managers | Branch Manager | No |
| audit1, audit2 | auditors | Auditor | No |
| itadmin | sudo | IT Administrator | Yes (port 2222) |

Default password for all users: `Branch@2024` (forced change on first login)
