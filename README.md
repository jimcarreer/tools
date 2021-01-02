# Tools

This is just a repo where I throw weird crap, scripts, little projects and
other odds and ends I use on Linux.  Also, I'm going to use it to document
small issues I encounter using it as my primary OS and the fixes or work
arounds for them.

## GDM/GDM3 Multimonitor Fix

To force the login screen of GDM to be on the correct monitor, that is to say
the primary monitor selected as a user, do the following:
```
sudo cp ~/.config/monitors.xml ~gdm/.config/monitors.xml
sudo chown gdm:gdm ~gdm/.config/monitors.xml
```
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

