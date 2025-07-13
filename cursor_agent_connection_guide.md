# Cursor Agent Connection Guide

## Current Agent Connection Details

### ✅ This Agent (Now Ready)
- **Public IP**: `3.12.82.200`
- **Private IPs**: 172.30.0.2, 172.17.0.1
- **SSH Status**: ✅ Running (PID 2666)
- **Port**: 22 (default SSH)
- **User**: ubuntu
- **OS**: Ubuntu 25.04 (Plucky)

### SSH Connection Command
```bash
ssh -i your-key.pem ubuntu@3.12.82.200
```

### SSH Host Keys (for verification)
- **RSA**: `SHA256:4y00Ll3kQCYGDbviy58C7CbO6TH2f/u1ZibEHillHyw`
- **ECDSA**: `SHA256:eTbCnUtweaPZyNxHXtzXPAHV8CbqQ1uL39+cL9TrLRw`
- **ED25519**: `SHA256:v4R+uQCe2F1/gl166hCbsm7ZkiXZiTRSyypHsjvLt/c`

## General Agent Connection Troubleshooting

### 1. Get Current Agent IP
If you need to find the IP of any agent, run these commands from within the agent:

```bash
# Get public IP
curl -s ifconfig.me
curl -s http://169.254.169.254/latest/meta-data/public-ipv4  # AWS EC2 specific

# Get private IPs
hostname -I

# AWS instance details
curl -s http://169.254.169.254/latest/meta-data/instance-id
```

### 2. Check SSH Service Status
```bash
# Check if SSH is installed
which sshd

# Check if SSH is running
ps aux | grep sshd

# Install SSH if needed
sudo apt update && sudo apt install -y openssh-server

# Start SSH service
sudo service ssh start
# or
sudo systemctl start ssh

# Enable SSH to start on boot
sudo systemctl enable ssh
```

### 3. Common Connection Issues & Solutions

#### ❌ Connection Timeout
**Causes:**
- Wrong IP address (most common)
- Security group not allowing SSH (port 22)
- SSH service not running
- Network connectivity issues

**Solutions:**
```bash
# Verify correct IP
curl -s ifconfig.me

# Check security groups in AWS console
# Ensure inbound rule: Type=SSH, Protocol=TCP, Port=22, Source=Your IP or 0.0.0.0/0

# Test connectivity
telnet <ip-address> 22
nc -zv <ip-address> 22
```

#### ❌ Permission Denied (publickey)
**Causes:**
- Wrong SSH key
- Key not in authorized_keys
- Incorrect file permissions

**Solutions:**
```bash
# Check key permissions (should be 600)
chmod 600 your-key.pem

# Add key to agent (if you have access)
ssh-copy-id -i your-key.pem ubuntu@<ip-address>

# Or manually add to authorized_keys
cat your-key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### ❌ Host Key Verification Failed
**Solutions:**
```bash
# Remove old host key
ssh-keygen -R <ip-address>

# Connect with host key checking disabled (first time)
ssh -o StrictHostKeyChecking=no -i your-key.pem ubuntu@<ip-address>
```

### 4. Setting Up New Agents

If you need to set up SSH on a new agent:

```bash
# Install SSH server
sudo apt update && sudo apt install -y openssh-server

# Start and enable SSH
sudo systemctl start ssh
sudo systemctl enable ssh

# Configure SSH (optional)
sudo nano /etc/ssh/sshd_config
# Key settings:
# Port 22
# PasswordAuthentication no  # Use keys only
# PubkeyAuthentication yes

# Restart SSH after config changes
sudo systemctl restart ssh

# Add your public key
mkdir -p ~/.ssh
echo "your-public-key-content" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 5. AWS-Specific Considerations

#### Security Groups
Ensure your security group has:
- **Type**: SSH
- **Protocol**: TCP
- **Port Range**: 22
- **Source**: Your IP address or 0.0.0.0/0 (less secure)

#### Key Pairs
- Use the correct key pair associated with the instance
- Download and save the .pem file securely
- Never share private keys

#### Instance State
- Instance must be in "running" state
- Public IP can change if instance is stopped/started
- Use Elastic IP for static public IP

### 6. Testing Connection

```bash
# Quick connectivity test
ping <ip-address>

# Port connectivity test
telnet <ip-address> 22
nc -zv <ip-address> 22

# SSH connection test
ssh -o ConnectTimeout=10 -i your-key.pem ubuntu@<ip-address> whoami
```

### 7. Cursor IDE Configuration

In Cursor, you can set up remote connections:

1. **Command Palette** (Ctrl+Shift+P)
2. **Remote-SSH: Connect to Host**
3. **Add New SSH Host** or select existing
4. Enter: `ubuntu@3.12.82.200`
5. Select SSH config file to update
6. Connect and enter key passphrase if needed

### 8. SSH Config File Example

Create/edit `~/.ssh/config`:

```
Host cursor-agent-1
    HostName 3.12.82.200
    User ubuntu
    IdentityFile ~/.ssh/your-key.pem
    StrictHostKeyChecking no
    ServerAliveInterval 60

Host cursor-agent-*
    User ubuntu
    IdentityFile ~/.ssh/your-key.pem
    StrictHostKeyChecking no
    ServerAliveInterval 60
```

Then connect with: `ssh cursor-agent-1`

## Quick Checklist for Connection Issues

- [ ] Correct IP address
- [ ] SSH service running on target
- [ ] Security group allows port 22
- [ ] Correct SSH key
- [ ] Key has proper permissions (600)
- [ ] User exists on target system
- [ ] Network connectivity to target

## Need Help?

If you continue having issues:
1. Share the exact error message
2. Confirm the IP you're trying to connect to
3. Verify the instance is running in AWS console
4. Check security group settings
5. Test with: `ssh -v` for verbose debugging