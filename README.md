# saltan(8)

An [OpenBSD](https://www.openbsd.org) daemon monitoring the [sshd(8)](https://man.openbsd.org/sshd) authentication log file and notifying [pftbld(8)](https://github.com/mpfr/pftbld) on accepted and/or rejected authentication attempts.

For further information, please have a look at the [manpage](https://mpfr.net/man/saltan/current/saltan.8.html).

## How to install

Make sure you're running `OpenBSD-current`. Otherwise, one of the following branches might be more appropriate:
* [7.3-stable](https://github.com/mpfr/saltan/tree/7.3-stable)
* [7.2-stable](https://github.com/mpfr/saltan/tree/7.2-stable)

Then, make sure your user (e.g. `mpfr`) has sufficient `doas` permissions.

```
$ cat /etc/doas.conf
permit nopass mpfr
```

Download and extract the source files into the user's home directory, here `/home/mpfr`.

```
$ cd
$ pwd
/home/mpfr
$ doas rm -rf saltan-current/
$ ftp -Vo - https://codeload.github.com/mpfr/saltan/tar.gz/current | tar xzvf -
saltan-current
saltan-current/LICENSE
saltan-current/README.md
saltan-current/docs
saltan-current/docs/saltan.8.html
saltan-current/pkg
saltan-current/pkg/accept
saltan-current/pkg/accept/accepted
saltan-current/pkg/reject
saltan-current/pkg/reject/banner_exchange
saltan-current/pkg/reject/connection_closed_by_authenticating_user
saltan-current/pkg/reject/disconnected_from_authenticating_user
saltan-current/pkg/reject/disconnecting_authenticating_user
saltan-current/pkg/reject/invalid_user
saltan-current/pkg/reject/unable_to_negotiate
saltan-current/pkg/saltan.conf
saltan-current/pkg/saltan.rc
saltan-current/src
saltan-current/src/Makefile
saltan-current/src/saltan.8
saltan-current/src/saltan.sh
```

Install daemon, manpage, service script, modules and a sample configuration file.

```
$ cd saltan-current/src
$ doas make fullinstall
install -c -o root -g bin -m 555  /home/mpfr/saltan-current/src/saltan.sh ...
install -c -o root -g bin -m 444  saltan.8 /usr/local/man/man8/saltan.8 ...
mkdir -p /etc/saltan/{accept,reject}
cp /root/saltan-current/src/../pkg/accept/* /etc/saltan/accept
cp /root/saltan-current/src/../pkg/reject/* /etc/saltan/reject
install -c -o root -g bin -m 555  /home/mpfr/saltan-current/src/../pkg/saltan...
cp /root/saltan-current/src/../pkg/saltan.conf /etc/saltan
```

> For further usage, the following list of available installation targets might be helpful:
> target name | description
> ----------- | -----------
> `fullinstall` | installs daemon, manpage, service script, modules and a sample configuration file if a configuration file not yet exists
> `fulluninstall` | deletes everything installed by `fullinstall` but ignores `/etc/saltan` if files have changed
> `install` | installs daemon and manpage only
> `modsupdate` | updates included modules to their latest version
> `reinstall` | runs `fulluninstall`, then `fullinstall modsupdate`
> `uninstall` | deletes daemon and manpage
> `update` | runs `all fullinstall`

Activate the service script and configure the notification sockets.

```
$ doas rcctl enable saltan
```

Make sure `pftbld(8)` is installed and running.

```
$ doas rcctl check pftbld
pftbld(ok)
```

Synchronize `saltan` and `pftbld` configuration files.

`saltan.conf`:

```
...
#acceptsock	none
rejectsock	/var/run/pftbld-ssh.sock
...
```

`pftbld.conf`:

```
target "ssh" {
	...
	socket "/var/run/pftbld-ssh.sock"
	...
}
```

Reload `pftbld` and start the `saltan` daemon.

```
$ doas rcctl reload pftbld
pftbld(ok)
$ doas rcctl start saltan
saltan(ok)
```

## How to uninstall

Stop the `saltan` daemon.

```
$ doas rcctl stop saltan
saltan(ok)
```

Deactivate the service script.

```
$ doas rcctl disable saltan
```

Uninstall daemon, manpage and service script.

```
$ cd ~/saltan-current/src
$ doas make fulluninstall
rm /usr/local/man/man8/saltan.8 /usr/local/sbin/saltan
rm /etc/rc.d/saltan
(not deleting /etc/saltan as files have changed)
```

Modules, configuration and source directory need to be removed manually, if no longer needed.

```
$ doas rm -rf /etc/saltan ~/saltan-current
```
