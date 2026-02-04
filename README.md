# Nextcloud High Availability Cluster

Automated deployment of a high availability Nextcloud cluster with Ansible.

## SECURITY WARNINGS

**BEFORE STARTING:**
- Configure `inventory.ini` with your IPs and credentials
- Create `sudo_pass.txt` with ansible-vault
- Generate secure passwords for Galera and Nextcloud
- Configure SSL certificates in `bddssl/`
- NEVER commit `inventory.ini`, `sudo_pass.txt`, or `bddssl/`
- Save Ansible Vault passwords in a password manager

**IMPORTANT:**
- HA Cluster requires **minimum 3 servers**
- Configure servers with SSH and sudo access
- SSL certificates are required for Galera replication
- Test first in a development environment

## Architecture

### Components

- **Nextcloud**: CMS/Cloud storage (Docker Swarm)
- **Galera Cluster**: MySQL database with multi-master replication
- **GlusterFS**: Distributed storage for Nextcloud files
- **Keepalived**: Virtual IP for high availability
- **HAProxy**: Load balancing (optional, in `ancien/`)
- **Docker Swarm**: Container orchestration

### Topology

```
+------------------------------------------+
|  Virtual IP (Keepalived)                 |
|  192.168.1.100                           |
+------------------+-----------------------+
                   |
           +-------+--------+
           |                |
   +-------v----+    +------v---+    +--------+
   |Server1    |    |Server2   |    |Server3 |
   |           |    |          |    |        |
   |Nextcloud      Nextcloud      Nextcloud |
   |Galera         Galera         Galera    |
   |GlusterFS      GlusterFS      GlusterFS |
   +-----------+    +----------+    +--------+
```

## Prerequisites

- **Servers**: Minimum 3 Linux servers (Ubuntu/Debian recommended)
- **Resources**:
  - CPU: 2+ cores per server
  - RAM: 4+ GB per server
  - Disk: 50+ GB per server
- **Network**:
  - SSH access to all servers
  - Servers on the same local network
  - Virtual IP available
- **Local tools**:
  - Ansible 2.9+
  - Python 3.6+

## Installation

### 1. Initial Configuration

```bash
# Copy the inventory
cp inventory.ini.example inventory.ini

# Edit with your IPs and credentials
nano inventory.ini
```

### 2. Create the sudo password file (Ansible Vault)

```bash
# Create a vault password file
ansible-vault create sudo_pass.txt

# File content: the sudo password for your servers
# Example: my_sudo_password
```

### 3. Generate SSL certificates for Galera

```bash
# Certificates must be placed in bddssl/
# See Galera documentation for generation:
# https://galeracluster.com/library/documentation/ssl-cert.html

mkdir -p bddssl
# Generate CA, server cert, client cert
```

### 4. Full Deployment

```bash
# Install all dependencies and services
./installAll.sh

# Or step by step:
ansible-playbook -i inventory.ini install_dependencies.yml
ansible-playbook -i inventory.ini install_docker.yml
ansible-playbook -i inventory.ini install_glusterfs.yml
ansible-playbook -i inventory.ini install_galera.yml
ansible-playbook -i inventory.ini install_swarm.yml
ansible-playbook -i inventory.ini install_nextcloud.yml
ansible-playbook -i inventory.ini install_keepalived.yml
```

## Configuration

### inventory.ini

Important variables to configure:

```ini
# Virtual IP (Keepalived)
vip=192.168.1.100

# Passwords - CHANGE THESE VALUES!
galera_root_password=your_secure_password
nextcloud_db_password=your_secure_password

# Servers
server1 ansible_host=192.168.1.101 ansible_user=admin
server2 ansible_host=192.168.1.102 ansible_user=admin
server3 ansible_host=192.168.1.103 ansible_user=admin
```

### sudo_pass.txt

Created with ansible-vault to securely store the sudo password:

```bash
# Create
ansible-vault create sudo_pass.txt

# Edit
ansible-vault edit sudo_pass.txt

# View
ansible-vault view sudo_pass.txt
```

### SSL Certificates (bddssl/)

Required structure:

```
bddssl/
|---- ca-key.pem       # Certificate Authority private key
|---- ca.pem           # Certificate Authority certificate
|---- server-key.pem   # Server private key
|---- server-cert.pem  # Server certificate
|---- client-key.pem   # Client private key
\---- client-cert.pem  # Client certificate
```

## Usage

### Accessing Nextcloud

Once deployed, access via the Virtual IP:

```
http://192.168.1.100/
```

Or via any server directly:

```
http://192.168.1.101/
http://192.168.1.102/
http://192.168.1.103/
```

### Check Cluster Status

```bash
# Galera cluster status
ansible galera -i inventory.ini -m shell -a "mysql -e 'SHOW STATUS LIKE \"wsrep_cluster_size\";'"

# GlusterFS volumes
ansible glusterfs -i inventory.ini -m shell -a "gluster volume info"

# Docker Swarm nodes
ansible docker -i inventory.ini -m shell -a "docker node ls"

# Keepalived status
ansible keepalived -i inventory.ini -m shell -a "systemctl status keepalived"
```

## Uninstallation

```bash
# Uninstall all components
./uninstallAll.sh

# Or by component:
ansible-playbook -i inventory.ini uninstall_nextcloud.yml
ansible-playbook -i inventory.ini uninstall_keepalived.yml
ansible-playbook -i inventory.ini uninstall_swarm.yml
ansible-playbook -i inventory.ini uninstall_galera.yml
ansible-playbook -i inventory.ini uninstall_glusterfs.yml
ansible-playbook -i inventory.ini uninstall_docker.yml
ansible-playbook -i inventory.ini uninstall_dependencies.yml
```

## Troubleshooting

### Galera cluster does not start

```bash
# Check status
ansible galera -i inventory.ini -m shell -a "systemctl status mariadb"

# Check logs
ansible galera -i inventory.ini -m shell -a "journalctl -u mariadb -n 50"

# Bootstrap the cluster if necessary (on server1)
ssh server1
sudo galera_new_cluster
```

### GlusterFS volume inaccessible

```bash
# Check peers
ansible glusterfs -i inventory.ini -m shell -a "gluster peer status"

# Check volume
ansible glusterfs -i inventory.ini -m shell -a "gluster volume status"

# Repair if necessary
ansible glusterfs -i inventory.ini -m shell -a "gluster volume heal <volume-name> info"
```

### Keepalived VIP not working

```bash
# Check which machine has the VIP
ansible keepalived -i inventory.ini -m shell -a "ip addr show | grep 192.168.1.100"

# Check logs
ansible keepalived -i inventory.ini -m shell -a "journalctl -u keepalived -n 50"
```

## Security

### Best Practices

1. **Passwords**: Use strong passwords (> 20 characters)
   ```bash
   # Generate secure passwords
   openssl rand -base64 32
   ```

2. **Ansible Vault**: Always encrypt secrets
   ```bash
   ansible-vault encrypt sudo_pass.txt
   ```

3. **SSL/TLS**: Use valid certificates for Galera
4. **Firewall**: Configure iptables/ufw to restrict access
5. **Backups**: Regularly back up:
   - Galera databases
   - GlusterFS volumes
   - Nextcloud config

### Ports Used

- **22**: SSH
- **80/443**: HTTP/HTTPS (Nextcloud)
- **3306**: MySQL/Galera
- **4444**: Galera SST
- **4567**: Galera cluster communication
- **4568**: Galera IST
- **24007-24008**: GlusterFS management
- **49152+**: GlusterFS bricks

## Project Structure

```
nextcloudHA/
|---- install_*.yml           # Installation playbooks
|---- uninstall_*.yml         # Uninstallation playbooks
|---- installAll.sh          # Full installation script
|---- uninstallAll.sh        # Full uninstallation script
|---- inventory.ini          # Ansible configuration (DO NOT COMMIT)
|---- inventory.ini.example  # Inventory template
|---- sudo_pass.txt          # Vault password (DO NOT COMMIT)
|---- templates/             # Jinja2 templates
|   |---- docker-compose.yml.j2
|   |---- 60-galera.cnf.j2
|   \---- ...
|---- bddssl/                # SSL certificates (DO NOT COMMIT)
\---- ancien/                # Old configurations (K3s, HAProxy)
```

## References

- **Nextcloud**: https://nextcloud.com/
- **Galera Cluster**: https://galeracluster.com/
- **GlusterFS**: https://www.gluster.org/
- **Keepalived**: https://www.keepalived.org/
- **Docker Swarm**: https://docs.docker.com/engine/swarm/

## Project Status

**Test/Training Project**

- Tested in development environment
- Configuration for 3 servers
- Requires adaptation for production

## License

Personal project - Private use
