## Modular Linux Configurator 

This repo contains all the custom scripts and programs that I run on my Raspberry Pi's and Proxmox server. Each folder is a module that has the setup scripts to automatically configure a stock Pi running Raspbian.

It is similar to Ansible as running the script sets up the Pi over the network and does not require attaching a keyboard and/or display. 


## Pi Projects: (photos of the projects are in each modules folder)

(airpi) - Portable AirPlay and Bluetooth Speaker

(aptcam) - Motion Detecting IR Security Camera (uploads videos to Google Drive)

(btpi) - Bluetooth Receiver (add bluetooth support to a vintage stereo system)

(hifi) - AirPlay and Bluetooth Receiver (optical and coaxial audio outputs)

(hfifmini) - AirPlay and Bluetooth Receiver (custom bedroom audio system 2x20watts)

(homepi) - Motion Detecting IR Security Camera Hub (for family home, two exernal cameras)

(ledgrid) - 8x8 Grid of RGB LED's (over 30 effects, each syncs up over Wi-Fi)

(ledwall) - 93 Pixel Ring of RGB LED's (over 30 effects, each syncs up over Wi-Fi)

(nespi) - RetroPi Emulator (runs old PS1, GBA, N64, NES games on a Sony Trinitron CRT TV)

(touchpi) - Touch Screen Home Automation Interface (runs custom web UI and controls LED strips)


The folder 'rpi' contains the programs/configs that are global to all the Pi projects and gets installed first before the specific module gets installed. It sets up Raspbian to boot in read/only mode using an OverlayFS, meaning all SD card writes are written to RAM. Changes made are not saved unless the command 'rpi rw' is entered on the Pi. this reboots it in read/write mode.

The 'login' script that configures the Pi automatically switches to read/write mode before installing. The read/only boot was done because of OS corruption issues I encountered on the Pi's after unplugging them. In the read/only mode the Pi can be unplugged without having to login to issue the shutdown command. Other features that the global configuration has is that it disables all unnecessary disk writes and logs are written to RAM, a cleanup
script is ran every 5 hours to make sure RAM usage stays low.

The global setup script can be found at 'rpi/config/installer.sh' it installs many APT packages used for the various projects. A custom web server is installed that allows for network settings to be changed using a browser. Making the Pi a embedded solution requiring no keyboard/display to setup. The web interface can change/connect to a Wi-Fi network, switch the Pi to wireless hotspot mode creating its own Wi-Fi network and monitor CPU/RAM usage. The Pi will automictically switch
to hotspot mode if a local Wi-Fi network cannot be found on boot.

This repo can run on any Linux server as all the tools used are standard to most installations. The 'login' script is used to manage and setup a stock Pi. The folder names for the modules are the hostnames of each Pi on my network, the setup script will automatically change the Pi's hostname to the module name and install the custom programs when using the 'init' argument. All arguments for
the login script are listed below.


## Pi / Server Configuration and Login Script

Login to ProOS Pi / Server
./login "Hostname"

Sync ProOS (quick run config script) Pi / Server
./login "Hostname" sync

Reset ProOS (full config script) Pi Only
./login "Hostname" reset

Reset ProOS & Reinstall Packages (full config script) Pi Only
./login "Hostname" reinstall

Clean/Restore ProOS (delete /opt/rpi and run full config script) Pi Only
./login "Hostname" clean

Initialize ProOS (configure a base Pi or reconfigure one) Pi Only
./login "Module" init "Hostname"

Command Reference List
./login cmds

* Clean-up Temporary Files
./login rmtmp


## Server VMs: 
** located in the 'pve' folder

(automate) - Home Automation Container (runs the custom web interface and backend services)

(files) - SMB File Server Container (software ZFS RAID 3x4TB's mirrored configuration)

(plex) - Plex Media Server (access local music and videos over the internet)

(config) - Proxmox Hypervisor (configuration for my home server)


** The SSH keys for the Pi's are not included in the repo, a new private key must be generated and setup on the server at the location '.ssh/rpi.rsa' and the public key included at the location '/rpi/config/authorized_keys' this will be uploaded to the Pi the first time the login script is ran. The Pi must have root login over SSH enabled with password auth turned on at first. This will allow the login script to connect over the network to the Pi. Once the setup script is complete it will disable password auth root login and only allow the RSA key based login this is done to enhance security and allow for password-less configuration of each Pi project.

### by Ben Provenzano III