
MAN=		saltan.8

BINDIR?=	/usr/local/sbin
MANDIR?=	/usr/local/man/man

realinstall:
	${INSTALL} ${INSTALL_COPY} -o ${BINOWN} -g ${BINGRP} -m ${BINMODE} \
		${.CURDIR}/saltan.sh ${DESTDIR}${BINDIR}/saltan

uninstall:
	-rm ${BINDIR}/saltan ${MANDIR}8/${MAN}

CONFFILE=	saltan.conf

.if exists(${.CURDIR}/../pkg/saltan.rc) && exists(${.CURDIR}/../pkg/${CONFFILE}) && exists(${.CURDIR}/../pkg/accept) && exists(${.CURDIR}/../pkg/reject)

CONFDIR=	/etc/saltan

fullinstall: install modsupdate
	${INSTALL} ${INSTALL_COPY} -o ${BINOWN} -g ${BINGRP} -m ${BINMODE} \
		${.CURDIR}/../pkg/saltan.rc /etc/rc.d/saltan
	@-if test -f ${CONFDIR}/${CONFFILE}; then echo "(configuration file exists, not touching ${CONFDIR}/${CONFFILE})"; else mkdir -p ${CONFDIR} && echo "cp ${.CURDIR}/../pkg/${CONFFILE} ${CONFDIR}" && cp ${.CURDIR}/../pkg/${CONFFILE} ${CONFDIR}; fi

fulluninstall: uninstall
	-rm /etc/rc.d/saltan
	@-if test -d ${CONFDIR}; then if test -z "$$(diff -x saltan.rc -aqr ${.CURDIR}/../pkg ${CONFDIR})"; then echo "rm -r ${CONFDIR}" && rm -r ${CONFDIR}; else echo "(not deleting ${CONFDIR} as files have changed)"; fi; fi

modsupdate:
	mkdir -p ${CONFDIR}/{accept,reject}
	-cp ${.CURDIR}/../pkg/accept/* ${CONFDIR}/accept
	-cp ${.CURDIR}/../pkg/reject/* ${CONFDIR}/reject

reinstall: fulluninstall fullinstall

update: all fullinstall

.endif

.include <bsd.prog.mk>
