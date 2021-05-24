# saltan(8)

An [OpenBSD](https://www.openbsd.org) daemon monitoring the [sshd(8)](https://man.openbsd.org/sshd) authentication log file and notifying [pftbld(8)](https://github.com/mpfr/pftbld/tree/6.9-stable) on accepted and/or rejected authentication attempts.

For further information, please have a look at the [manpage](https://mpfr.net/man/saltan/6.9-stable/saltan.8.html).

## How to install

Make sure you're running `OpenBSD 6.9-stable`. Otherwise, one of the following branches might be more appropriate:
* [current](https://github.com/mpfr/saltan)
* [6.8-stable](https://github.com/mpfr/saltan/tree/6.8-stable)

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
$ doas rm -rf saltan-6.9-stable/
$ ftp -Vo - https://codeload.github.com/mpfr/saltan/tar.gz/6.9-stable | tar xzvf -
saltan-6.9-stable
saltan-6.9-stable/LICENSE
saltan-6.9-stable/README.md
saltan-6.9-stable/docs
saltan-6.9-stable/docs/mandoc.css
saltan-6.9-stable/docs/saltan.8.html
saltan-6.9-stable/pkg
saltan-6.9-stable/pkg/accept
saltan-6.9-stable/pkg/accept/accepted
saltan-6.9-stable/pkg/reject
saltan-6.9-stable/pkg/reject/connection_closed_by_authenticating_user
saltan-6.9-stable/pkg/reject/disconnected_from_authenticating_user
saltan-6.9-stable/pkg/reject/disconnecting_authenticating_user
saltan-6.9-stable/pkg/reject/invalid_user
saltan-6.9-stable/pkg/reject/unable_to_negotiate
saltan-6.9-stable/pkg/saltan.conf
saltan-6.9-stable/pkg/saltan.rc
saltan-6.9-stable/src
saltan-6.9-stable/src/Makefile
saltan-6.9-stable/src/saltan.8
saltan-6.9-stable/src/saltan.sh
```

Install daemon, manpage, service script, modules and a sample configuration file.

```
$ cd saltan-6.9-stable/src
$ doas make fullinstall
install -c -o root -g bin -m 555  /home/mpfr/saltan-6.9-stable/src/saltan.sh ...
install -c -o root -g bin -m 444  saltan.8 /usr/local/man/man8/saltan.8 ...
install -c -o root -g bin -m 555  /home/mpfr/saltan-6.9-stable/src/../pkg/saltan...
cp /root/saltan-6.9-stable/src/../pkg/!(saltan.rc) /etc/saltan
```

> For further usage, the following list of available installation targets might be helpful:
> target name | description
> ----------- | -----------
> `fullinstall` | installs the daemon's binary, manpage, service script, modules and a sample configuration file, if no other configuration file exists
> `install` | installs the daemon's binary and manpage only
> `reinstall` | runs `uninstall`, then `fullinstall`
> `uninstall` | removes everything installed by `fullinstall`
> `update` | installs binary and manpage, intended to be used when updating an existing installation
> `modsupdate` | runs `update` with modules included

Activate the service script and configure the notification sockets.

```
$ doas rcctl enable saltan
```

Make sure `pftbld(8)` is installed and running.

```
$ doas rcctl check pftbld
pftbld(ok)
```

Adapt the `saltan` and `pftbld` configuration files.

`saltan.conf`

```
...
#acceptsock	none
failsock	/var/run/pftbld-ssh.sock
...
```

`pftbld.conf`:

```
target "ssh" {
	...
	socket "/var/run/pftbld-ssh.sock"
	idlemin 500
	cascade {
		keep states
		...
	}
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
$ cd ~/saltan-6.9-stable/src
$ doas make uninstall
rm /etc/rc.d/saltan /usr/local/man/man8/saltan.8 /usr/local/sbin/saltan
(configuration has changes, not touching /etc/saltan)
```

Modules, configuration and source directory need to be removed manually, if no longer needed.

```
$ doas rm -rf /etc/saltan ~/saltan-6.9-stable
```
