# [`nixos`](https://github.com/exprpapi/nixos)

System configuration for my main workhorse

<details><summary>

## Installation
</summary>

1. Boot up the NixOS ISO and open a terminal.
2. Clone and navigate to this repo.
   ```bash
   git clone 'https://github.com/exprpapi/nixos-config'
   cd nixos-config
   ```
3. Determine the disk (`"${DISK}"`) you want to use.
   ```bash
   lsblk | grep disk
   ```
4. Finally run the installer on that disk and reboot:
   ```bash
   sudo sh install.sh "${DISK}"
   ```

</details>
