# Tools

This is just a repo where I throw weird crap, scripts, little projects and
other odds and ends I use on Linux.  Also, I'm going to use it to document
small issues I encounter using it as my primary OS and the fixes or work
arounds for them.

## Rotate Console Frame Buffer

The screen on my file server needs to be rotated to be readable.

When intalling a fresh OS use Ctrl + Alt + F2 to switch to a different TTY. Then run:
`echo 3 | sudo tee /sys/class/graphics/fbcon/rotate`

The frame buffer needs to be rotated counter-clockwise.

After OS is installed, change the rotation permanently by adding:

`GRUB_CMDLINE_LINUX="fbcon=rotate:3"`

To `/etc/default/grub` and running `sudo update-grub`

[Reference](https://askubuntu.com/questions/237963/how-do-i-rotate-my-display-when-not-using-an-x-server)

## GDM/GDM3 Multimonitor Fix

To force the login screen of GDM to be on the correct monitor, that is to say
the primary monitor selected as a user, do the following:
```
sudo cp ~/.config/monitors.xml ~gdm/.config/monitors.xml
sudo chown gdm:gdm ~gdm/.config/monitors.xml
```

**Note: The bug below seems fixed in whatever Wayland version comes with 22.04**

Also, for the time being, if wayland is installed and the default for GDM it 
must be disabled in `/etc/gdm3/custom.conf` and modifying it to set:
```
WaylandEnable=false
```
The bug seems to be in wayland. [Reference](https://bugzilla.redhat.com/show_bug.cgi?id=1184617#c4).

## Permission Denied to Snap accessing Symlinked NFS Stuff

Snap can access things on NFS fine, but Apparmor will shut that down quickly.

It usually results in crap like:
```
journalctl -f -t audit | grep gimp
Jan 02 10:26:00 jim-pc audit[32956]: AVC apparmor="DENIED" operation="open" profile="snap.gimp.gimp" name="/mnt/raid/jim/Pictures/" pid=32956 comm="pool" requested_mask="r" denied_mask="r" fsuid=1000 ouid=1000
```

This can be fixed by granting the specific app specific perms to the linked NFS.
Add the line `owner /mnt/raid/jim/Pictures/ rwl,` near the line
`owner @{HOME}/ r,` in the file for the specific snap app armor profile. For
example gimps is usually:
```
/var/lib/snapd/apparmor/profiles/snap.gimp.gimp
```

Needs to be reloaded via:
```
sudo apparmor_parser -r /var/lib/snapd/apparmor/profiles/snap.gimp.gimp
```

[Solution Reference](https://forum.snapcraft.io/t/snaps-and-nfs-home/438/26)

## Discord Audit Spams

Discord likes to touch other parts of the system for things like "what game are you playing".

This results in audit spam like:
```
Jan 02 10:50:51 jim-pc audit[36859]: AVC apparmor="DENIED" operation="ptrace" profile="snap.discord.discord" pid=36859 comm="Discord" requested_mask="read" denied_mask="read" peer="unconfined"
Jan 02 10:50:51 jim-pc audit[36859]: AVC apparmor="DENIED" operation="ptrace" profile="snap.discord.discord" pid=36859 comm="Discord" requested_mask="read" denied_mask="read" peer="unconfined"
```

In the kernel logs, this can be fixed with:
```
snap connect discord:system-observe :system-observe
snap connect discord:unity7 :unity7
```

Additionally, disabling things like Settings > Game Activity seems to help.

[Solution Reference](https://github.com/snapcrafters/discord/issues/23#issuecomment-390735227)

## Setting up GMail as Email Relay

Install postfix and update `/etc/postfix/main.cf` with the following settings:

    relayhost = [smtp.gmail.com]:587
    smtp_sasl_auth_enable = yes
    smtp_sasl_security_options = noanonymous
    smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
    smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
    smtp_use_tls = yes

I also add the following line:

    mydestination = jim-fs.jimcarreer.com jimcarreer.com gravis.io localhost jim-fs

to catch undeliverable emails leaking out (root@jim-fs, etc ...)

Create the specified `sasl_passwd` above under `/etc/postfix` and add the following line:

    [smtp.gmail.com]:587 <email>:<password>

replacing `<email>` and `<password>` with a gmail address and an **application password** generated for it.

Run the following commands to update postfix and restart:

    sudo postmap /etc/postfix/sasl_passwd
    sudo service postfix restart

Testing that it is working properly:

    echo "This is a test email." | mail -s "Test email" recipient_email_address

[Solution Reference](https://www.tutorialspoint.com/configure-postfix-to-use-gmail-smtp-on-ubuntu)
