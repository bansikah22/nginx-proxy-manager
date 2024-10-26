### Install Pi Hole
#### Launch Instance with mininum requirements
```bash
multipass launch --name pihole --cpus 1 --memory 512M --disk 4G
```
#### Set a static IP address
```bash
multipass set local.driver=network-manager
multipass restart
```
##### After Restart
```bash
multipass info pihole
```
Install Pi-hole on the VM.
SSH into the VM and run the following commands:
```bash
multipass exec pihole -- sudo bash -c "$(curl -sSL https://install.pi-hole.net)"
```
### Access Pi-hole Interface
```bash
multipass exec pihole -- pihole -a
http://<Multipass-Instance-IP>/admin
```
#### Get default password and set new password
```bash
multipass exec pihole -- pihole -a -p
multipass exec pihole -- pihole -a -p ""
##shell to reset password
multipass shell pihole
pihole -a -p
defaut user :pi.hole
```

## use temporary script to install Pi-hole
```bash
# Download the script to a temporary file
multipass exec pihole -- wget -O install.sh https://install.pi-hole.net

# Execute the installation script
multipass exec pihole -- sudo bash install.sh

# Optionally, remove the script after installation
multipass exec pihole -- rm install.sh
```