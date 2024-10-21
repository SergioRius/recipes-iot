## Frigate containerized install (LXC) with Google Coral support.

Creating the Frigate container.
Execute the following command in Proxmox cli:

```bash
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/ct/frigate.sh)"
```

### Adding our cameras to configuration

We remove the test stream from the Frigate configuration and add the specific configuration for our camera(s).

```diff
mqtt:
  enabled: true
  host: 10.1.5.43
cameras:
-   test:
-     ffmpeg:
-       #hwaccel_args: preset-vaapi
-       inputs:
-         - path: /media/frigate/person-bicycle-car-detection.mp4
-           input_args: -re -stream_loop -1 -fflags +genpts
-           roles:
-             - detect
-             - rtmp
-     detect:
-       height: 1080
-       width: 1920
-       fps: 5
+  Portal:
+    enabled: True
+    ffmpeg:
+      inputs:
+        - path: rtsp://<user>:<password>@10.1.6.30:554/ch=1&subtype=1
+          roles:
+            - detect
+    onvif:
+      host: 10.1.6.30
+      port: 80
+      user: <user>
+      password: <password>
model:
  path: /cpu_model.tflite
```

### Google Coral

First, issue a `lsusb` command at the Host command line to ensure that the Coral device is attached.

```bash
$ lsusb
...
Bus 001 Device 002: ID 8087:8008 Intel Corp. Integrated Rate Matching Hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 003: ID 1a6e:089a Global Unichip Corp. 
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
...
```

We take note of the BusId and the DeviceId for the device marked as "Global Unichip..." for later usage. In this case, 004 and 003.

We create an udev rule for the device:

```bash
cat <<EOT >> /etc/udev/rules.d/70-edgetpu.rules
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a6e", ATTRS{idProduct}=="089a", MODE="0664", TAG+="uaccess", OWNER="100000", GROUP="100000"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="9302", MODE="0664", TAG+="uaccess", OWNER="100000", GROUP="100000"
EOT
```

And reload to apply the new rules:

```bash
udevadm control --reload-rules && udevadm trigger
```

Edit the container configuration file

```bash
nano /etc/pve/lxc/100.conf
```

Comment or remove all the USB rules added by the script, and add the tree last lines:

```diff
#<div align='center'><a href='https%3A//Helper-Scripts.com' target='_blank' rel='noopener noreferrer'><img src='https%3A//raw.githubusercontent.com>
#
#  # Frigate LXC
#
#  <a href='https%3A//ko-fi.com/D1D7EP4GF'><img src='https%3A//img.shields.io/badge/&#x2615;-Buy me a coffee-blue' /></a>
#  </div>
arch: amd64
cores: 4
features: nesting=1
hostname: frigate
memory: 1024
nameserver: 10.1.5.251
net0: name=eth0,bridge=vmbr0,gw=10.1.5.251,hwaddr=AE:DA:E3:69:7F:6B,ip=10.1.5.31/24,tag=5,type=veth
net1: name=net1,bridge=vmbr1,firewall=1,gw=10.1.6.5,hwaddr=72:9B:56:28:7C:68,ip=10.1.6.10/24,type=veth
onboot: 1
ostype: debian
rootfs: vega-local-lvm:vm-100-disk-0,size=20G
swap: 512
tags: proxmox-helper-scripts
-lxc.cgroup2.devices.allow: a
-lxc.cap.drop: 
-lxc.cgroup2.devices.allow: c 188:* rwm
-lxc.cgroup2.devices.allow: c 189:* rwm
-lxc.mount.entry: /dev/serial/by-id  dev/serial/by-id  none bind,optional,create=dir
-lxc.mount.entry: /dev/ttyUSB0       dev/ttyUSB0       none bind,optional,create=file
-lxc.mount.entry: /dev/ttyUSB1       dev/ttyUSB1       none bind,optional,create=file
-lxc.mount.entry: /dev/ttyACM0       dev/ttyACM0       none bind,optional,create=file
-lxc.mount.entry: /dev/ttyACM1       dev/ttyACM1       none bind,optional,create=file
-lxc.cgroup2.devices.allow: c 226:0 rwm
-lxc.cgroup2.devices.allow: c 226:128 rwm
-lxc.cgroup2.devices.allow: c 29:0 rwm
-lxc.mount.entry: /dev/fb0 dev/fb0 none bind,optional,create=file
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file

+lxc.cgroup2.devices.allow: c 29:0 rwm
+lxc.cgroup2.devices.allow: c 189:* rwm
+lxc.mount.entry: /dev/bus/usb/004 dev/bus/usb/004 none bind,optional,create=dir 0, 0
```

You can leave the GPU passthrough lines.

Reboot the container.

Then we ssh into the Frigate container to install and execute the Coral example.

```bash
apt update -y && apt install -y gnupg2 usbutils

git clone https://github.com/google-coral/pycoral.git && cd pycoral

bash examples/install_requirements.sh classify_image.py

python3 examples/classify_image.py \
    --model test_data/mobilenet_v2_1.0_224_inat_bird_quant_edgetpu.tflite \
    --labels test_data/inat_bird_labels.txt \
    --input test_data/parrot.jpg
```

The output should be simmilar to the following one:

```bash
----INFERENCE TIME----
Note: The first inference on Edge TPU is slow because it includes loading the model into Edge TPU memory.
11.3ms
2.6ms
2.6ms
2.7ms
2.6ms
-------RESULTS--------
Ara macao (Scarlet Macaw): 0.75781
```

Now our device shows as Google on the Host console, and it's now available for use on the container, so we add the following definition to Frigate's configuration file:

```yaml
detectors:
 coral:
   type: edgetpu
   device: usb
```

And we are ready to go!

```log
[INFO] Preparing Frigate...
[INFO] Starting Frigate...
[2024-06-16 21:18:36] frigate.app                    INFO    : Starting Frigate (0.13.2-)
[2024-06-16 21:18:38] peewee_migrate.logs            INFO    : Starting migrations
[2024-06-16 21:18:38] peewee_migrate.logs            INFO    : There is nothing to migrate
[2024-06-16 21:18:38] frigate.app                    INFO    : Recording process started: 1278
[2024-06-16 21:18:38] frigate.app                    INFO    : go2rtc process pid: 124
[2024-06-16 21:18:38] frigate.app                    INFO    : Output process started: 1289
[2024-06-16 21:18:38] frigate.app                    INFO    : Camera processor started for Portal: 1297
[2024-06-16 21:18:38] frigate.app                    INFO    : Capture process started for Portal: 1299
[2024-06-16 21:18:38] detector.coral                 INFO    : Starting detection process: 1288
[2024-06-16 21:18:38] frigate.detectors.plugins.edgetpu_tfl INFO    : Attempting to load TPU as usb
[2024-06-16 21:18:41] frigate.detectors.plugins.edgetpu_tfl INFO    : TPU found
```