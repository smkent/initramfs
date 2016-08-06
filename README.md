# Simple initramfs generator for Gentoo Linux

These tools generate the initramfs images I use on my Gentoo Linux machines.
These initramfs images are designed to be very simple, with only the following
features:

* Assemble software RAID
  ([md](https://raid.wiki.kernel.org/index.php/Linux_Raid)) devices
* Prompt for the passphrase needed to mount a dm-crypt (cryptsetup) encrypted
  root filesystem
* Start a DHCP client and SSH server to allow an encrypted root filesystem
  passphrase to be entered via SSH

These scripts were written with my particular setup in mind, and make a number
of assumptions.

## Prerequisites

Your kernel must include all the hardware support needed for disk detection,
networking, software RAID, filesystems, etc., as this initramfs does not load
any kernel modules.

To build an initramfs image, the following programs must be installed:

* [busybox](https://www.busybox.net/) (`sys-apps/busybox`)
* If the root filesystem is encrypted:
  * [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/)
    (`sys-fs/cryptsetup`)
  * [dhcpcd](http://roy.marples.name/projects/dhcpcd) (`net-misc/dhcpcd`)
  * [dropbear](https://matt.ucc.asn.au/dropbear/dropbear.html)
    (`net-misc/dropbear`)
* If the root filesystem is on a Linux software RAID (md) device:
  * [mdadm](http://neil.brown.name/blog/mdadm) (`sys-fs/mdadm`)

The build tool will attempt to determine and include libraries needed for any
of these executables that are linked dynamically, however initramfs
construction will be simpler and more reliable for any binaries that are linked
statically. Currently, I am using a statically-linked version of busybox and
cryptsetup. In general, packages may be statically linked on Gentoo Linux by
installing them with `USE="static"` set.

## Usage

To create an initramfs image for the current machine, simply run:

```shell
$ sudo ./build-initramfs
```

The initramfs will be saved to `initramfs.cpio.gz` in the same directory as the
build script.

To create an initramfs image for another machine, you can override the
hostname, root block device, and other options using command line arguments.
Run `./build-initramfs --help` for a complete list.

## Initramfs construction

The `build-initramfs` script follows this process to create an initramfs image:

* Determine the root block device.
  * If the root block device is encrypted, determine the underlying block
    device.
  * If the root block device is a software RAID (md) device, use the "friendly"
    /dev/md/\* named path if available instead of the numbered /dev/mdXXX name.
    For example, prefer `/dev/md/root` over `/dev/md125`.
* If the root block device is encrypted, determine the /dev/mapper/\* name in
  use, or fall back to `root_crypt` as a default.
* Determine the current hostname
* Determine the user to authorize ssh login keys for, or fall back to
  `$SUDO_USER` if none specified
* Install the needed character and block device nodes
* Install executables and dynamically loaded libraries needed within the
  initramfs
* Create disk, DHCP client, and SSH server configuration
  * To allow SSH login in the initramfs, authorized\_keys are added from:
    * `~/.ssh/id_rsa.pub`
    * `~/.ssh/authorized_keys`
    * Any `sshPublicKey` entries found for the specified user in the LDAP
      database
  * Re-use the same ECDSA host key currently in use with OpenSSH on the current
    machine (see below for security note)
* Package and compress initramfs image

## Security note

When the SSH server (dropbear) is configured in the initramfs, the same ECDSA
host key that OpenSSH currently uses is copied to the initramfs. If the root
filesystem of the current machine is encrypted, this means the SSH host key is
now stored in the initramfs, which is unencrypted. If unauthorized access is
gained to the physical machine, the SSH host key should be considered
compromised even though the root filesystem may be encrypted.

## References

Inspiration for remote root filesystem unlock started with Debian cryptsetup's
instructions, available on a Debian installation at
`/usr/share/doc/cryptsetup/README.remote.gz`. This file no longer seems to be
Debian's current cryptsetup package, but [a copy of README.remote is
available](/doc/debian/README.remote). That file details Debian-specific
initramfs configuration instructions.

## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

See [`LICENSE`](/LICENSE) for the full license text.
