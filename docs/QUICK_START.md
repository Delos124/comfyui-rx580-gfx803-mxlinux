# Quick start

After completing [Installation](INSTALLATION.md):

**Start**
```bash
./scripts/start.sh
```

Open http://127.0.0.1:8188 in your browser.

**Stop**
```bash
./scripts/stop.sh
```

**Check the installation**
```bash
./scripts/diagnose.sh
```

**Verify optional IP-Adapter**
```bash
bash ./scripts/verify-ipadapter.sh
```

This checks that the IP-Adapter model loader/apply nodes are registered and that the SD 1.5 model files are present. It does not replace a real image-generation test. See [IP-Adapter setup](IP_ADAPTER.md).

**Install MX Linux application-menu launchers**
```bash
./scripts/install-desktop.sh
```

This adds separate Start and Stop entries to your application menu. The Start entry opens a terminal and may request your sudo password. The Stop entry stops the container without deleting model or output files.

**Back up your user data**
```bash
./scripts/backup.sh /path/to/backup-folder
```

Replace `/path/to/backup-folder` with a real directory on another disk. Keep at least one backup copy separate from the computer's main storage.
