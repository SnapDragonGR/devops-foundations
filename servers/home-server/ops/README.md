# ops - backups and weekly updates for MCPC

Scripts live in `bin/` and are installed to `/usr/local/bin/`. Units live in `systemd/`
and are installed to `/etc/systemd/system/`. `pc/` holds what runs on the PC (gleb-arch).
Secrets are NOT in this repo. They are in `/etc/homelab/` on the server (mode 600) and in
`~/.config/mcpc-backup/` on the PC. The vault password is also in the password manager.

## What runs when

- Every night 04:30 (server): `homelab-backup --nightly`. Settings, databases and the
  Minecraft world go into the vault at `/srv/media/data/backups/restic`.
- Every 4 hours while logged in (PC): `mcpc-pull` copies the vault to
  `/mnt/archive/mcpc-backups/restic` through a read-only login.
- Monthly (PC): `mcpc-restore-test` proves that the copy can be restored.
- Thursday 02:00 (server): `homelab-update`. Snapshot, Debian updates, new container
  images, health check, rollback if something broke, reboot if needed.

## Useful commands (server)

    sudo homelab-status                      # last backup, last update, snapshots, quarantine
    sudo homelab-smoke-test                  # the health check
    sudo homelab-update --dry-run            # show what the update would do
    sudo homelab-rollback RUN APP            # put one app back (RUN = name of a folder
                                             # /var/lib/homelab-update/run-RUN)
    ls /var/log/homelab-update/              # one log per update run

A rollback keeps the broken settings as `/srv/media/config/APP.failed-RUN`. Remove such a
folder by hand once you no longer need it. `/var/lib/homelab-update/quarantine.json` lists
images that failed; they are skipped until a newer image appears. Debian's own automatic
upgrades are switched off in `/etc/apt/apt.conf.d/99-homelab-no-auto-upgrade`.

## The server died - rebuild from the PC copy

1.  Install Debian 13 on the new disk: host name MCPC, user gleb, address 192.168.31.218.
2.  Install Docker (docker-ce with the compose plugin), the NVIDIA driver and
    nvidia-container-toolkit, and: `apt install restic sqlite3 jq curl bind9-dnsutils git`.
3.  Mount the media disk at `/srv/media/data`. If that disk died too, create the folder
    on a new disk; the media itself is not in the backup.
4.  On the PC, copy the vault to the server:
    `rsync -a /mnt/archive/mcpc-backups/restic/ gleb@192.168.31.218:restic-copy/`
5.  On the server, as root, restore the newest settings snapshot into a work folder
    (it asks for the vault password from the password manager):
    `restic -r /home/gleb/restic-copy restore latest --tag config --target /root/restore`
6.  Put the pieces in place, keeping owners (`cp -a`): `/root/restore/srv/media/config`
    to `/srv/media/config`, `/root/restore/srv/media/compose` to `/srv/media/compose`,
    `/root/restore/etc/homelab` to `/etc/homelab`, `/root/restore/home/gleb/minecraft-fabric/.env`
    to its place. Compare `/root/restore/etc/fstab` and `/root/restore/etc/ssh` with the new
    system by hand; do not copy them blindly.
7.  Databases are stored apart as safe copies. Put them in, file by file:
    `cd /root/restore/srv/media/data/backups/staging/db/srv/media/config && find . -type f -exec cp -a --parents {} /srv/media/config/ \;`
8.  Minecraft world: `restic -r /home/gleb/restic-copy restore latest --tag minecraft --target /`
9.  `git clone` this repo to `~/devops-foundations`, recreate the two `.env` links
    (`servers/home-server/compose/.env` -> `/srv/media/compose/.env`,
    `servers/mc-server/.env` -> `/home/gleb/minecraft-fabric/.env`), then start the media
    stack from `servers/home-server/compose/`.
10. Reinstall these scripts and units from `ops/`, and move the vault copy to
    `/srv/media/data/backups/restic` (owner root, group backupro, see the build guide).
11. `/root/restore/srv/media/data/backups/staging/host-state/` lists the packages, mounts,
    timers and image versions the old server had.
12. Run `sudo homelab-smoke-test`. Then delete `/root/restore`: it holds secrets.
