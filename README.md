# Build and import a ZenHub Enterprise image for Triton

The build scripts for the ZenHub image are split into "local" (`build.sh`) and
"remote" (`remote.sh`) components. The local component depends on VMWare's
OVF Tool, which is only available for Linux, macOS, and Windows. The remote
component depends on tools which run on a Triton compute node (I usually
use a sandbox headnode) running SmartOS.

The local script (`build.sh`) expects to be run on a Linux machine
The value of `BUILD_HOST` in the `build.sh` should be a Triton compute node
(often a sandbox headnode) with sufficient privileges to run `vmadm` and
`sdc-imgadm`.

A small KVM instance in JPC running Ubuntu 17.04 is sufficient for the local bits.
The unpacked vmdk is ~6 GB, so I strongly suggest
running the local portion in the datacenter closest to the compute node you'll
use for your remote build host.

You'll need to
[download and install VMWare's `ovftool`](https://www.vmware.com/support/developer/ovf/)
and install it on the machine where you invoke `build.sh`

You'll also want to make sure to add the appropriate keys to the remote host's
authorized_keys files to enable password-less SSH between your local build and
remote build hosts.

1. Clone this repo and all submodules (e.g. `git clone --recursive …`)
1. Run `./build.sh`

## Step-by-step instructions for building and troubleshooting the image

### Prepare to build the image…

1. Clone this repo locally, as above
1. Copy the relevant bits of `./tools/ssh-config` into your `~/.ssh/config` file
1. `$ rsync --exclude=.git* -rcv . ubuntu@<ip>:/mnt/`
1. Make sure you've got a working VNC client on your machine. I use [VNC Viewer from RealVNC](https://www.realvnc.com/en/connect/download/viewer/macos/)

### Building the image…

*NOTE: If you'd like to be able to get a console on the intermediate instance
used in the conversion process (useful for troubleshooting image conversion),
you'll want to comment out the last line of `./image-converter/convert-image`
so that it reads `# clean-up`.*

1. `$ ssh ubuntu@<ip>`
1. `$ cd /mnt/zenhub-enterprise-triton-image`
1. `$ ./build.sh`

### Testing / Troubleshooting

This presumes you did as noted above and commented out the last line of 
`./image-converter/convert-image` so that it reads `# clean-up`.

You can safely start and connect to the intermediate instance once the build
script has created a snapshot of it and started creating the image file(s)
(indicated by `==> Creating image file...`)

1. Open `https://sandbox-adminui.sbox.joyent.us/vms` in a browser
1. Find the VM w/ the uuid of the instance created by your image conversion
   script (look through the script output for `==> Creating blank VM...`; the
   instance uuid will be on the following line)
1. If that VM is stopped, start it.
1. Once it has started, run `vmadm info <uuid>`; at the bottom of the output,
   you'll see a block that shows a port number for connecting to the console
   using VNC
1. On your local machine, run `./tools/sandbox-hn-vnc.sh <portnumber>`
1. Open `./tools/zenhub-test (hn).vnc` in VNC Viewer and set the port number
   for the connection to the same one you got from `vmadm info` above.
1. You should now have a console on the intermediate instance.

https://www.vmware.com/support/developer/ovf/ovf420/ovftool-420-userguide.pdf