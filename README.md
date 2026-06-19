# BC-250 Ollama and Open WebUI

This guide is meant to be a step by step guide for turning an AMD BC-250 crypto mining hardware into a headless Self-Hosted LLM endpoint based on Debian Forky. This guide assumes you have a functional BC-250 with a modified bios plugged into a wired network, for more information on purchasing and setting up one please see the [great documentation](https://elektricm.github.io/amd-bc250-docs/) maintained by [Martin Dolez](https://github.com/elektricM).

This guide is designed for novices, we will cover basic concepts that might seem obvious to users that are used to installing Linux and a command line.

The lion's share of this guide is derived from [akandr's](https://github.com/akandr) work in [https://github.com/akandr/bc250](https://github.com/akandr/bc250).

## OS install

This will be a headless server based on Debian Forky (testing) to maximize available memory for LLMS. For initial setup you will need: 

* A BC-250 hooked into a wired network
* Keyboard and monitor for initial installation
* A client computer capable of running an SSH terminal on the same network
* A USB drive with at least 1gb of capacity

### USB drive preperation

On your client machine you will need to download the Debian testing iso to image to your USB stick [https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso](https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso).

#### Windows

Download [Rufus](https://rufus.ie/):

* Insert USB drive
* Select Debian file you just downloaded
* Choose GPT partition scheme
* Select UEFI target system
* Click START

#### macOS

Download [Etcher](https://www.balena.io/etcher/):

* Select Debian file you just downloaded
* Select USB target
* Click Flash!

#### Linux

Determine the drive assignment for your USB drive: 

```
sudo fdisk -l |grep -A1 'Disk /'
```

Example output: 

```
Disk /dev/nvme0n1: 953.87 GiB, 1024209543168 bytes, 2000409264 sectors
Disk model: SAMSUNG MZVL21T0HCLR-00B00              
--
Disk /dev/sda: 57.3 GiB, 61524148224 bytes, 120164352 sectors
Disk model: Cruzer Glide 
```

In this example the USB drive is `/dev/sda`. 

Download and write the iso image to the USB drive using dd: (replace sdX with the drive you identified)

```
wget https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso
sudo dd bs=4M if=debian-testing-amd64-netinst.iso of=/dev/sdX status=progress oflag=sync
```

### Installing Debian

This section will go into extreme detail, most users can likely skip this, but if you are a novice or question any step of the install please refer to the photos in the guide. (apologies for the phone photos I lack a displayport capture solution)

1. With the BC-250 powered off insert your USB stick, a USB keyboard, a network cable, and a monitor connected over display port.

2. Power on the BC-250 and mash the F11 key over and over again until you see the boot selection menu and select your USB drive to boot from:

![debian1](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian1.jpg)

3. From the grub boot splash select `Install`:

![debian2](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian2.jpg)

4. Once the text installer is loaded select your language (English in my case):

![debian3](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian3.jpg)

5. Select your keyboard layout (United States in my case):

![debian4](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian4.jpg)

6. Next select your keymap (American English in my case):

![debian5](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian5.jpg)

7. Now you will set a hostname for the system, I use bc250 here:

![debian6](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian6.jpg)

8. Next set the domain for most users this will be the default `lan`:

![debian7](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian7.jpg)

9. You will be prompted for a root password **IT IS IMPORTANT YOU LEAVE THIS BLANK FOR DEBIAN TO AUTOMATICALLY SETUP SUDO FOR YOU**:

![debian8](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian8.jpg)

10. Again when asked to verify leave this password field blank:

![debian9](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian9.jpg)

11. Now you will create your user I use thelamer here:

![debian10](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian10.jpg)

12. This will be the username you use to login to the device over ssh, again I use thelamer here:

![debian11](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian11.jpg)

13. Next set your password and re-enter it to verify you entered it correctly this will be your ssh password:

![debian12](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian12.jpg)

14. Select your timezone:

![debian13](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian13.jpg)

15. For disk partitioning we are going to use the entire disk, if you are doing a dual boot setup or something else you should know what you are doing here. For this guide we are turning this entire BC-250 blade into an LLM interface: 

![debian14](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian14.jpg)

16. Next select the disk to use, this should be an nvme device name:

![debian15](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian15.jpg)

17. Select all files in one partition:

![debian16](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian16.jpg)

18. First change confirmation:

![debian17](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian17.jpg)

19. Second change confirmation to write changes:

![debian18](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian18.jpg)

20. Select your mirror, mine defaults to `United States`:

![debian19](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian19.jpg)

21. We use the default http mirror from Debian here `deb.debian.org`, this is generally the slowest option, but we do not ingest many packages anyway and it is universal:

![debian20](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian20.jpg)

22. Unless you have an HTTP proxy to configure just leave this blank: 

![debian21](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian21.jpg)

23. For software selection we want this to be a headless server so de-select `Debian desktop environment` and `GNOME`. Then select the `SSH server` option and leave `standard system utilities` selected:

![debian22](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian22.jpg)

24. Once you are splashed with `Installation complete` remove the USB drive and selct `Continue` this will reboot the machine: 

![debian23](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian23.jpg)

25. Once the machine is rebooted you will be greeted with a text login prompt, just type your username and password you setup during install: 

![debian24](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian24.jpg)

26. You will need to install a text editor to allow password authentication over ssh run `sudo apt-get update && sudo apt-get install vim nano -y`:

![debian25](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian25.jpg)

27. You will need to edit the sshd config file, in my case I am using vim with `sudo vim /etc/ssh/sshd_config` use the arrow keys to get down to the line `#PasswordAuthentication yes` press the delete key to remove the `#` and press colon `:` and type `wq` enter. If using nano you use `ctl+x` to write the file out. 

![debian26](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian26.jpg)

28. You need to restart ssh for the changes to take `sudo systemctl restart ssh`:

![debian27](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/debian27.jpg)

29. You will need to know the IP of the machine in order to SSH to it from your local network on your client machine. This can be achieved with `ip a`:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: enp4s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether a8:a1:59:b5:46:20 brd ff:ff:ff:ff:ff:ff
    altname enxa8a159b54620
    inet 192.168.10.200/24 brd 192.168.10.255 scope global noprefixroute enp4s0
       valid_lft forever preferred_lft forever
    inet6 fd13:cf85:f6e7:0:aaa1:59ff:feb5:4620/64 scope global dynamic mngtmpaddr proto kernel_ra 
       valid_lft forever preferred_lft 604676sec
    inet6 2001:1960:5c01:2167:aaa1:59ff:feb5:4620/64 scope global dynamic mngtmpaddr proto kernel_ra 
       valid_lft 85992sec preferred_lft 1392sec
    inet6 fd13:cf85:f6e7:0:1e5:66a4:51bc:ca75/64 scope global mngtmpaddr noprefixroute 
       valid_lft forever preferred_lft 604676sec
    inet6 2001:1960:5c01:2167:1c09:2d7f:82da:ec7b/64 scope global dynamic mngtmpaddr noprefixroute 
       valid_lft 85992sec preferred_lft 1392sec
    inet6 fe80::c180:785d:5e99:ed7e/64 scope link 
       valid_lft forever preferred_lft forever
```

In this blob you will see `inet 192.168.10.200/24` which means `192.168.10.200` is the ip address of the machine on my local network yours will be different. You might want to configure a static DHCP lease on your home router to pin it to a specific IP or use the hostname `bc250` to connect to it if your home network supports that.

Your headless server is ready to be interacted with remotely, at this point you can disconnect your keyboard and monitor, you only need SSH access fro the remainder of the steps.

## Setup over SSH

This will be how you access your BC-250 from here on out to make modifications to it. In order to SSH to the machine: 

#### Windows

Install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) and use the IP, username, and password we setup in the Debian install section.

#### macOS

On Apple devices ssh is built into the terminal simply `ssh username@ip` from the terminal and enter your password.

#### Linux

On Linux ssh client is usually baked in as well simply open a terminal and `ssh username@ip` and enter your password.

### Initial unlock scripts

For this guide we will not be overclocking or undervolting the system, but we will need to make some core modifications in order to unlock all our VRAM (16 gigs) and unlock all 40 CUs. 

#### Unlock 40 CUs

Github user [WinnieLV](https://github.com/WinnieLV) maintains [bc250-cu-live-manager](https://github.com/WinnieLV/bc250-cu-live-manager).

To run this simply ssh into the BC-250 and run: 

```
sudo apt-get update && sudo apt-get install curl -y
curl -L -o bc250-cu-live-manager.sh https://raw.githubusercontent.com/WinnieLV/bc250-cu-live-manager/refs/heads/main/bc250-cu-live-manager.sh
chmod +x bc250-cu-live-manager.sh
sudo ./bc250-cu-live-manager.sh
```

Now select y to install UMR:

```bash
+------------------------------------------------------------------------------+
| BC-250 CU Dashboard                                                          |
+------------------------------------------------------------------------------+
[WARN] UMR register view skipped; umr was not found.

+------------------------------------------------------------------------------+
| Actions                                                                      |
+------------------------------------------------------------------------------+
|  [e] Edit WGP table      [f] Enable all CUs      [t] Enable default CUs      |
|  [i] Install service     [w] Write table         [u] Uninstall service       |
|  [q] Quit                                                                    |
+------------------------------------------------------------------------------+


> UMR is not installed. Install it now? [y/n]: y
```

Once complete press enter to bring up the main menu: 

```bash
+------------------------------------------------------------------------------+
| BC-250 CU Dashboard / Live Dispatch                                          |
+------------------------------------------------------------------------------+
  UMR        : /usr/local/bin/umr
  UMR inst   : 0 (auto)
  ASIC       : cyan_skillfish.gfx1013
  amdgpu     : bc250_cc_write_mode=not exposed, active_cu_number=24
  Source     : SPI dispatch masks + amdgpu boot CU map
  Legend     : D+ driver+routed, S+ SPI+routed, D! driver+off, -- off

  +---------+------+------+------+------+------+------+------------+--------+
  | Row     | WGP0 | WGP1 | WGP2 | WGP3 | WGP4 | SPI  | CC         | CUs    |
  |         | 0-1  | 2-3  | 4-5  | 6-7  | 8-9  |      |            |        |
  +---------+------+------+------+------+------+------+------------+--------+
  | SE0.SH0 |  D+  |  D+  |  D+  |  --  |  --  | 0x07 | 0xfff80000 |   6/10 |
  | SE0.SH1 |  D+  |  D+  |  D+  |  --  |  --  | 0x07 | 0xfff80000 |   6/10 |
  | SE1.SH0 |  D+  |  D+  |  D+  |  --  |  --  | 0x07 | 0xfff80000 |   6/10 |
  | SE1.SH1 |  D+  |  D+  |  D+  |  --  |  --  | 0x07 | 0xfff80000 |   6/10 |
  +---------+------+------+------+------+------+------+------------+--------+

  CUs active & routed  : 24/40

+------------------------------------------------------------------------------+
| Actions                                                                      |
+------------------------------------------------------------------------------+
|  [e] Edit WGP table      [f] Enable all CUs      [t] Enable default CUs      |
|  [i] Install service     [w] Write table         [u] Uninstall service       |
|  [q] Quit                                                                    |
+------------------------------------------------------------------------------+

> Select action: f
```

First type f and enter: 

```bash
+------------------------------------------------------------------------------+
| Safety Disclaimer                                                            |
+------------------------------------------------------------------------------+
| This tool writes low-level AMDGPU registers on BC-250 hardware.              |
| Incorrect values can freeze the GPU, crash the system, or force a reboot.    |
| You may lose unsaved work and can increase power draw and thermals.          |
| No warranty is provided by the authors or contributors of this script.       |
| You are fully responsible for validation, monitoring, and any outcomes.      |
| Recommended: stable PSU, active cooling, and a remote shell fallback.        |
+------------------------------------------------------------------------------+
> Type 'accept' to continue or 'no' to cancel: accept

+------------------------------------------------------------------------------+
| Enable Full Dispatch                                                         |
+------------------------------------------------------------------------------+
  Legend: D+=driver+routed, S+=SPI+routed, D!=driver+off, --=off

  +---------+----------------+----------------+-----------------------+
  | Row     | Current        | Target         | Change                |
  +---------+----------------+----------------+-----------------------+
  | SE0.SH0 | D+ D+ D+ -- -- | D+ D+ D+ S+ S+ | W3+,W4+               |
  | SE0.SH1 | D+ D+ D+ -- -- | D+ D+ D+ S+ S+ | W3+,W4+               |
  | SE1.SH0 | D+ D+ D+ -- -- | D+ D+ D+ S+ S+ | W3+,W4+               |
  | SE1.SH1 | D+ D+ D+ -- -- | D+ D+ D+ S+ S+ | W3+,W4+               |
  +---------+----------------+----------------+-----------------------+

  Target total: 40/40 CUs
> Apply changes? [y/n]: y
```

Type accept and enter ,then y and enter, then enter again to return to the main menu.

Now type w and enter: 

```bash
+------------------------------------------------------------------------------+
| Confirm Boot Table Save                                                      |
+------------------------------------------------------------------------------+
| This will save the current live WGP table as the boot profile.               |
| The installed service will use this table on the next start/boot.            |
+------------------------------------------------------------------------------+
> Write current table to service config? [y/n]: y
[ OK ] saved boot table: SE0.SH0=0x1f SE0.SH1=0x1f SE1.SH0=0x1f SE1.SH1=0x1f
```

With the table written all that is left is to type i to install the systemd service: 

```
+------------------------------------------------------------------------------+
| Confirm Service Install                                                      |
+------------------------------------------------------------------------------+
| This will install and enable the boot service.                               |
| Use write-service-table when you want to change the saved WGP table.         |
+------------------------------------------------------------------------------+
> Install/update service? [y/n]: y
Created symlink '/etc/systemd/system/multi-user.target.wants/bc250-cu-live-manager.service' → '/etc/systemd/system/bc250-cu-live-manager.service'.
[ OK ] installed and enabled bc250-cu-live-manager.service
[ OK ] saved boot table will be applied on next boot; use apply-service to apply it now
```

Select q to quit now you are all set and should see all CU unlocked: 

```
+------------------------------------------------------------------------------+
| BC-250 CU Dashboard / Live Dispatch                                          |
+------------------------------------------------------------------------------+
  UMR        : /usr/local/bin/umr
  UMR inst   : 0 (auto)
  ASIC       : cyan_skillfish.gfx1013
  amdgpu     : bc250_cc_write_mode=not exposed, active_cu_number=24
  Service    : enabled
  Boot sync  : current table saved
  Source     : SPI dispatch masks + amdgpu boot CU map
  Legend     : D+ driver+routed, S+ SPI+routed, D! driver+off, -- off

  +---------+------+------+------+------+------+------+------------+--------+
  | Row     | WGP0 | WGP1 | WGP2 | WGP3 | WGP4 | SPI  | CC         | CUs    |
  |         | 0-1  | 2-3  | 4-5  | 6-7  | 8-9  |      |            |        |
  +---------+------+------+------+------+------+------+------------+--------+
  | SE0.SH0 |  D+  |  D+  |  D+  |  S+  |  S+  | 0x1f | 0xffe00000 |  10/10 |
  | SE0.SH1 |  D+  |  D+  |  D+  |  S+  |  S+  | 0x1f | 0xffe00000 |  10/10 |
  | SE1.SH0 |  D+  |  D+  |  D+  |  S+  |  S+  | 0x1f | 0xffe00000 |  10/10 |
  | SE1.SH1 |  D+  |  D+  |  D+  |  S+  |  S+  | 0x1f | 0xffe00000 |  10/10 |
  +---------+------+------+------+------+------+------+------------+--------+

  CUs active & routed  : 40/40
```

#### Unlock 16GB VRAM

While still SSH'd into the system run: 

```bash
echo 4194304 | sudo tee /sys/module/ttm/parameters/pages_limit
echo 4194304 | sudo tee /sys/module/ttm/parameters/page_pool_size
echo "options ttm pages_limit=4194304 page_pool_size=4194304" | \
  sudo tee /etc/modprobe.d/ttm-gpu-memory.conf
printf "w /sys/module/ttm/parameters/pages_limit - - - - 4194304\n\
w /sys/module/ttm/parameters/page_pool_size - - - - 4194304\n" | \
  sudo tee /etc/tmpfiles.d/gpu-ttm-memory.conf
sudo update-initramfs -u
```

With VRAM unlocked and 40 CUs unlocked lets reboot to ensure it is persistent: 

```bash
sudo reboot
```

Once the system is back up lets confirm our changes are working: 

```bash
sudo ./bc250-cu-live-manager.sh status
+------------------------------------------------------------------------------+
| BC-250 CU Dashboard / Live Dispatch                                          |
+------------------------------------------------------------------------------+
  UMR        : /usr/local/bin/umr
  UMR inst   : 0 (auto)
  ASIC       : cyan_skillfish.gfx1013
  amdgpu     : bc250_cc_write_mode=not exposed, active_cu_number=24
  Service    : enabled
  Boot sync  : current table saved
  Source     : SPI dispatch masks + amdgpu boot CU map
  Legend     : D+ driver+routed, S+ SPI+routed, D! driver+off, -- off

  +---------+------+------+------+------+------+------+------------+--------+
  | Row     | WGP0 | WGP1 | WGP2 | WGP3 | WGP4 | SPI  | CC         | CUs    |
  |         | 0-1  | 2-3  | 4-5  | 6-7  | 8-9  |      |            |        |
  +---------+------+------+------+------+------+------+------------+--------+
  | SE0.SH0 |  D+  |  D+  |  D+  |  S+  |  S+  | 0x1f | 0xffe00000 |  10/10 |
  | SE0.SH1 |  D+  |  D+  |  D+  |  S+  |  S+  | 0x1f | 0xffe00000 |  10/10 |
  | SE1.SH0 |  D+  |  D+  |  D+  |  S+  |  S+  | 0x1f | 0xffe00000 |  10/10 |
  | SE1.SH1 |  D+  |  D+  |  D+  |  S+  |  S+  | 0x1f | 0xffe00000 |  10/10 |
  +---------+------+------+------+------+------+------+------------+--------+

  CUs active & routed  : 40/40
```

```bash
cat /sys/module/ttm/parameters/pages_limit
4194304
cat /sys/module/ttm/parameters/page_pool_size
4194304
```

### Installing Ollama host level

Again credit goes to [akandr](https://github.com/akandr) here for their [guide](https://github.com/akandr/bc250).

For this guide we are going to install Ollama system level and Open WebUI via Docker.

SSH into the server and install ollama: 

```bash
curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
>>> Downloading ollama-linux-amd64.tar.zst
######################################################################## 100.0%
>>> Creating ollama user...
>>> Adding ollama user to render group...
>>> Adding ollama user to video group...
>>> Adding current user to ollama group...
>>> Creating ollama systemd service...
>>> Enabling and starting ollama service...
Created symlink '/etc/systemd/system/default.target.wants/ollama.service' → '/etc/systemd/system/ollama.service'.
>>> Downloading ollama-linux-amd64-rocm.tar.zst
######################################################################## 100.0%
>>> The Ollama API is now available at 127.0.0.1:11434.
>>> Install complete. Run "ollama" from the command line.
>>> AMD GPU ready.
```

Next lets set some overrides for this system, these can be modified later but I found good performance and model sizes with q4 and for programming tasks you will want a large context size: 

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment=OLLAMA_IGPU_ENABLE=1
Environment=OLLAMA_HOST=0.0.0.0
Environment=OLLAMA_KEEP_ALIVE=30m
Environment=OLLAMA_MAX_LOADED_MODELS=1
Environment=OLLAMA_FLASH_ATTENTION=1
Environment=OLLAMA_GPU_OVERHEAD=0
Environment=OLLAMA_CONTEXT_LENGTH=65536
Environment=OLLAMA_MAX_QUEUE=4
OOMScoreAdjust=-1000
Environment=OLLAMA_KV_CACHE_TYPE=q4_0
EOF
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

Now confirm everything is setup properly: 

```bash
sudo journalctl -u ollama -n 20 | grep BC-250
Jun 19 11:38:28 bc250 ollama[1530]: time=2026-06-19T11:38:28.969-04:00 level=INFO source=runner.go:396 msg="dropping integrated GPU; to enable, set OLLAMA_IGPU_ENABLE=1" id=0 library=Vulkan compute=0.0 name=Vulkan0 description="AMD BC-250 (RADV GFX1013)" pci_id=0000:01:00.0
Jun 19 11:40:54 bc250 ollama[1703]: time=2026-06-19T11:40:54.287-04:00 level=INFO source=types.go:32 msg="inference compute" id=0 filter_id=0 library=Vulkan compute=0.0 name=Vulkan0 description="AMD BC-250 (RADV GFX1013)" libdirs=ollama,vulkan driver=0.0 pci_id=0000:01:00.0 type=iGPU total="16.5 GiB" available="16.5 GiB"
```

You should see 16.5GB available and your device `AMD BC-250 (RADV GFX1013)` here. You can now use ollama via the command line if you want: 

```bash
ollama run gemma4:e4b
pulling manifest 
pulling 4c27e0f5b5ad: 100% ▕█████████████████████████████████████████████████████████████████████████████▏ 9.6 GB                         
pulling 7339fa418c9a: 100% ▕█████████████████████████████████████████████████████████████████████████████▏  11 KB                         
pulling 56380ca2ab89: 100% ▕█████████████████████████████████████████████████████████████████████████████▏   42 B                         
pulling f0988ff50a24: 100% ▕█████████████████████████████████████████████████████████████████████████████▏  473 B                         
verifying sha256 digest 
writing manifest 
success 
>>> hello what are you ? 
Thinking...
Thinking Process:

1.  **Identify the user's query:** The user asked "hello what are you?". This is a request for self-identification and definition.
2.  **Recall Core Identity Instructions:** I need to state my name, nature, developer, and general function accurately, following the 
persona guidelines.
    *   Name: Gemma 4
    *   Nature: Large Language Model (LLM)
    *   Developer: Developed by Google DeepMind
    *   Type/Weights: Open weights model
3.  **Draft the response:** Construct a friendly, informative, and accurate response based on the core identity.

    *   *Greeting:* Acknowledge the user (e.g., "Hello!").
    *   *Core Identity:* State what I am (Gemma 4).
    *   *Function/Developer:* Explain my origin and purpose (developed by Google DeepMind, an LLM designed to assist, answer 
questions, etc.).

4.  **Review against constraints:**
    *   Did I use the name Gemma 4? Yes.
    *   Did I claim incorrect capabilities? No.
    *   Is the tone appropriate? Yes, helpful and informative.

5.  **Final Output Generation.** (This leads to the generated response.)
...done thinking.

Hello! I am **Gemma 4**, a Large Language Model developed by Google DeepMind.

Essentially, I am an AI designed to help you with information, complete tasks, generate creative content, answer questions, and hold 
conversations. You can ask me anything, and I will do my best to provide accurate and helpful responses!

How can I assist you today?

>>> Send a message (/? for help)
```

Use ctl+c and ctrl+d to exit this interface. 

### Installing docker

While it is possible to natively install Open WebUI natively the juice is not worth the squeeze, they need specific versions of python and deps so it is much easier and better supported to use their Docker image. 

This blob will get docker installed, this is essentially their install instructions with the repo being hardcoded to `trixie` as Forky does not have a repo: 

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

Once complete logout with ctrl+d and ssh back in, you should be able to run `docker ps -a`: 

```bash
docker ps -a 
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

### Setting up OpenWebUI and reverse proxy

We have included a script in this repo to automate this process, it will setup a docker compose file, create self signed certs, and setup a reverse proxy for Open WebUI. 

SSH into your BC-250 and run: 

```
mkdir openwebui && cd openwebui
curl -sSL https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/compose-setup.sh | bash
```

You will then be able to access https://yourip, setup your admin account, and start using Open WebUI.

TTS is pre-setup with this stack

#### Try some models

In order to load new models from the web interface simply click on the down arrow in the top left of the screen and enter the model name IE `qwen2.5-coder:14b` and click on `Pull "qwen2.5-coder:14b" from Ollama.com`: 

![models](https://raw.githubusercontent.com/thelamer/bc250-ollama-openwebui/master/img/models.jpg)

Some models I have had luck with: 

* `gemma4:e4b` - This is a speedy model with good logic and thinking. With this there is plenty of headroom on ram usage.
* `gemma4:12b` - Another great model from the gemma4 family.
* `qwen2.5-coder:14b` - This is an excellent programming model, combined with the large context it can handle most daily programming tasks.
* `gemma4:26b` - This is the absolute top end I got to run and is not recommended, you will bleed a bit into swap using this and the performance is not steller. This does function though. (don't blame me if your BC-250 locks up using this)

Just in general this is a moving target you will want to keep up with new model releases and use what fits your needs. 

[https://ollama.com/library](https://ollama.com/library)

### Service management and uninstall

From time to time you may need to update your containers or stop them: 

Update: 

```bash
cd openwebui
docker compose pull
docker compose up -d
```

Stop services: 

```bash
cd openwebui
docker compose down
```

After the stack is stopped you can uninstall all data with:

```bash
cd ~
sudo rm -Rf openwebui/
```
