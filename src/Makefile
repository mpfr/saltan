
MAN=		saltan.8

BINDIR?=	/usr/local/sbin
MANDIR?=	/usr/local/man/man

realinstall:
	${INSTALL} ${INSTALL_COPY} -o ${BINOWN} -g ${BINGRP} -m ${BINMODE} \
		${.CURDIR}/saltan.sh ${DESTDIR}${BINDIR}/saltan

CONFFILE=	saltan.conf

.if exists(${.CURDIR}/../pkg/saltan.rc) && exists(${.CURDIR}/../pkg/${CONFFILE}) && exists(${.CURDIR}/../pkg/accept) && exists(${.CURDIR}/../pkg/reject)

CONFDIR=	/etc/saltan

fullinstall: install
	${INSTALL} ${INSTALL_COPY} -o ${BINOWN} -g ${BINGRP} -m ${BINMODE} \
		${.CURDIR}/../pkg/saltan.rc /etc/rc.d/saltan
	@-if test -d ${CONFDIR}; then echo "(configuration directory ${CONFDIR} exists, not touching)"; else mkdir -p ${CONFDIR} && echo "cp ${.CURDIR}/../pkg/!(saltan.rc) ${CONFDIR}" && cp -R ${.CURDIR}/../pkg/!(saltan.rc) ${CONFDIR} && chmod go-wx ${CONFDIR}/{accept,reject}/*; fi

uninstall:
	-rm /etc/rc.d/saltan ${BINDIR}/saltan ${MANDIR}8/${MAN}	
	@-if test -d ${CONFDIR}; then if test -z "$$(diff -x saltan.rc -aqr ${.CURDIR}/../pkg ${CONFDIR})"; then echo "rm -r ${CONFDIR}" && rm -r ${CONFDIR}; else echo "(configuration has changes, not touching ${CONFDIR})"; fi; fi

reinstall: uninstall fullinstall

update: all install

modsupdate: update
	@-mkdir -p ${CONFDIR}/{accept,reject}
	-cp ${.CURDIR}/../pkg/accept/* ${CONFDIR}/accept
	-cp ${.CURDIR}/../pkg/reject/* ${CONFDIR}/reject

.endif

.include <bsd.prog.mk>
