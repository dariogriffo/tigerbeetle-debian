# TigerBeetle systemd Service

This Debian package includes systemd service support for running TigerBeetle as a system service.

## What's Included

The package installs the following files:

- `/usr/local/bin/tigerbeetle` - The TigerBeetle binary
- `/usr/local/bin/tigerbeetle-pre-start.sh` - Pre-start script that formats the data file if it doesn't exist
- `/lib/systemd/system/tigerbeetle.service` - systemd service unit file

## Default Configuration

The service is configured with the following defaults:

- **Cluster ID**: 0
- **Replica Index**: 0
- **Replica Count**: 1 (single-node cluster)
- **Address**: 3001
- **Cache Grid Size**: 1GiB
- **Data File**: `/var/lib/tigerbeetle/0_0.tigerbeetle`

## Usage

### Enable and Start the Service

After installing the package, enable and start the service:

```bash
sudo systemctl enable tigerbeetle.service
sudo systemctl start tigerbeetle.service
```

### Check Service Status

```bash
sudo systemctl status tigerbeetle.service
```

### View Logs

```bash
sudo journalctl -u tigerbeetle.service -f
```

### Stop the Service

```bash
sudo systemctl stop tigerbeetle.service
```

### Disable the Service

```bash
sudo systemctl disable tigerbeetle.service
```

## Customizing Configuration

To customize the service configuration, use systemd's drop-in file support:

```bash
sudo systemctl edit tigerbeetle.service
```

This will open an editor where you can override environment variables. For example:

```ini
[Service]
Environment=TIGERBEETLE_CACHE_GRID_SIZE=4GiB
Environment=TIGERBEETLE_ADDRESSES=0.0.0.0:3001
Environment=TIGERBEETLE_CLUSTER_ID=1
Environment=TIGERBEETLE_REPLICA_INDEX=0
Environment=TIGERBEETLE_REPLICA_COUNT=3
Environment=TIGERBEETLE_DATA_FILE=/var/lib/tigerbeetle/1_0.tigerbeetle
```

After making changes, reload systemd and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart tigerbeetle.service
```

## Multi-Node Cluster Setup

For a multi-node cluster, you'll need to:

1. Install the package on each node
2. Configure each node with appropriate settings using systemd drop-in files
3. Ensure the `TIGERBEETLE_ADDRESSES` environment variable includes all replica addresses
4. Set unique `TIGERBEETLE_REPLICA_INDEX` for each node
5. Use the same `TIGERBEETLE_CLUSTER_ID` and `TIGERBEETLE_REPLICA_COUNT` on all nodes

Example for a 3-node cluster:

**Node 1** (`systemctl edit tigerbeetle.service`):
```ini
[Service]
Environment=TIGERBEETLE_CLUSTER_ID=0
Environment=TIGERBEETLE_REPLICA_INDEX=0
Environment=TIGERBEETLE_REPLICA_COUNT=3
Environment=TIGERBEETLE_ADDRESSES=192.168.1.10:3001,192.168.1.11:3001,192.168.1.12:3001
Environment=TIGERBEETLE_DATA_FILE=/var/lib/tigerbeetle/0_0.tigerbeetle
```

**Node 2** (`systemctl edit tigerbeetle.service`):
```ini
[Service]
Environment=TIGERBEETLE_CLUSTER_ID=0
Environment=TIGERBEETLE_REPLICA_INDEX=1
Environment=TIGERBEETLE_REPLICA_COUNT=3
Environment=TIGERBEETLE_ADDRESSES=192.168.1.10:3001,192.168.1.11:3001,192.168.1.12:3001
Environment=TIGERBEETLE_DATA_FILE=/var/lib/tigerbeetle/0_1.tigerbeetle
```

**Node 3** (`systemctl edit tigerbeetle.service`):
```ini
[Service]
Environment=TIGERBEETLE_CLUSTER_ID=0
Environment=TIGERBEETLE_REPLICA_INDEX=2
Environment=TIGERBEETLE_REPLICA_COUNT=3
Environment=TIGERBEETLE_ADDRESSES=192.168.1.10:3001,192.168.1.11:3001,192.168.1.12:3001
Environment=TIGERBEETLE_DATA_FILE=/var/lib/tigerbeetle/0_2.tigerbeetle
```

## Development Mode

For development environments that don't support Direct IO or have memory constraints, you can add the `--development` flag:

```bash
sudo systemctl edit tigerbeetle.service
```

Add:
```ini
[Service]
ExecStart=
ExecStart=/usr/local/bin/tigerbeetle start --development --cache-grid=${TIGERBEETLE_CACHE_GRID_SIZE} --addresses=${TIGERBEETLE_ADDRESSES} ${TIGERBEETLE_DATA_FILE}
```

Note: You must clear the original `ExecStart` with an empty line before setting a new value.

## Security Features

The service includes several security hardening features:

- **DynamicUser**: Service runs with a dynamically allocated user
- **CAP_IPC_LOCK**: Capability to lock memory (required for TigerBeetle)
- **ProtectSystem**: Strict protection of system directories
- **RestrictAddressFamilies**: Limited to IPv4 and IPv6
- Various other protections for kernel, home directories, etc.

## Data Location

The service stores data in `/var/lib/tigerbeetle/` by default. This directory is automatically created with appropriate permissions by systemd.

## Troubleshooting

### Service fails to start

Check the logs:
```bash
sudo journalctl -u tigerbeetle.service -n 50
```

### Permission issues

Ensure the service has the CAP_IPC_LOCK capability. This is configured in the service file but may require system-level configuration in some environments.

### Memory locking issues

If you see memory locking errors, you may need to:

1. Give the tigerbeetle binary the CAP_IPC_LOCK capability:
   ```bash
   sudo setcap "cap_ipc_lock=+ep" /usr/local/bin/tigerbeetle
   ```

2. Or raise the global memlock value in `/etc/security/limits.conf`

3. Or use development mode (which disables memory locking)

## More Information

For more details about TigerBeetle deployment and configuration, see:
- [TigerBeetle Documentation](https://docs.tigerbeetle.com/)
- [systemd Deployment Guide](https://docs.tigerbeetle.com/operating/deploying/systemd/)

