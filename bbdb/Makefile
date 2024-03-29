

INSTALL = /bin/install -c
INSTALL_PROGRAM = ${INSTALL}
INSTALL_SCRIPT = ${INSTALL}
INSTALL_DATA = ${INSTALL} -m 644

RM   = /bin/rm -f
LN_S = ln -s

EMACS_PROG = /usr/local/bin/emacs -no-site-file -no-init-file

GNUSDIR = 
MHEDIR = 
VMDIR = 
OTHERDIRS = 

PACKAGEDIR = /usr/lib/xemacs/site-packages
SYMLINKS = no
LINKPATH = 

# this is lovely, isn't it?  Surprisingly enough, it seems to work...
VM	= -eval '(progn (if (not (string-match "$(VMDIR)" ""))            \
			    (setq load-path (cons "$(VMDIR)" load-path))) \
			(if (load "vm-version" t t)                         \
			    (cond ((> (string-to-number vm-version) 5.31) \
                                   (load "vm" t t))                           \
                                  (t (load "vm-vars" t t) (load "vm" t t)))))'

GNUS	= -eval '(if (not (string-match "$(GNUSDIR)" ""))             \
		     (setq load-path (cons "$(GNUSDIR)" load-path)))'

MHE	= -eval '(progn (if (not (string-match "$(MHEDIR)" ""))            \
			    (setq load-path (cons "$(MHEDIR)" load-path))) \
			(load "mh-e" t t))'

PUSHPATH=-l .././loadpath.el

.SUFFIXES: .elc .el .tar .Z .gz .uu

DEPSRCS=	bbdb-com.el  bbdb-hooks.el  bbdb-gnus.el  bbdb-mhe.el \
		bbdb-rmail.el bbdb-vm.el bbdb-ftp.el bbdb-whois.el \
		bbdb-xemacs.el bbdb-print.el bbdb-srv.el bbdb-reportmail.el \
		bbdb-merge.el bbdb-migrate.el bbdb-gui.el

DEPBINS=	${DEPSRCS:.el=.elc}
SRCS=		bbdb.el  $(DEPSRCS)
BINS=		bbdb.elc $(DEPBINS)

all: Makefile  gnus   bbdb autoloadsc

Makefile: Makefile.in
	@echo "Makefile.in has changed, rerun configure!"
	exit 1

install-pkg: uninstall-pkg bbdb autoloadsc
	@if test "x$(SYMLINKS)" = "xno" ; then                 \
          mkdir -p -m 0755 $(PACKAGEDIR)/lisp/bbdb;            \
          for i in `ls *.elc` ; do                             \
            $(INSTALL_DATA) `echo $$i | sed 's/c$$//g'`        \
                            $(PACKAGEDIR)/lisp/bbdb ;          \
            $(INSTALL_DATA) $$i $(PACKAGEDIR)/lisp/bbdb ;      \
          done ;                                               \
        else                                                   \
          if test "x$(LINKPATH)" = "x" ; then                  \
            $(LN_S) `pwd` $(PACKAGEDIR)/lisp/bbdb ;            \
          else                                                 \
            $(LN_S) $(LINKPATH)/lisp $(PACKAGEDIR)/lisp/bbdb ; \
          fi ;                                                 \
        fi

uninstall-pkg:
	-$(RM) -r $(PACKAGEDIR)/lisp/bbdb

bbdb-autoloads.el: $(DEPSRCS)
	@-$(RM) $@;
	@echo "(provide 'bbdb-autoloads)" > $@;
	@echo "(eval-when-compile" >> $@;
	@echo "  (condition-case ()" >> $@;
	@echo "      (require 'custom)" >> $@;
	@echo "    (error nil))" >> $@;
	@echo "  (if (and (featurep 'custom) (fboundp 'custom-declare-variable))()" >> $@;
	@echo "    (defmacro defgroup (&rest args)" >> $@;
	@echo "      nil)" >> $@;
	@echo "    (defmacro defcustom (var value doc &rest args)" >> $@;
	@echo "      \`(defvar ,var ,value ,doc))" >> $@;
	@echo "    (defmacro defface (var value doc &rest args)" >> $@;
	@echo "      \`(make-face ,var))" >> $@;
	@echo "    (defmacro define-widget (&rest args)" >> $@;
	@echo "      nil)))" >> $@;
	@echo "" >> $@;
	@$(EMACS_PROG) -batch -q -l autoload \
		--eval '(setq generated-autoload-file "'`pwd`'/$@")' \
		--eval "(if (featurep 'xemacs) (delete-file generated-autoload-file))" \
		--eval '(setq make-backup-files nil)' \
		--eval '(setq autoload-package-name "bbdb")' \
		-f batch-update-autoloads `pwd`

bbdb-autoloads.elc: bbdb-autoloads.el
	@$(EMACS_PROG) -batch -q -f batch-byte-compile ./$^

bbdb.elc:            bbdb.el
bbdb-com.elc:        bbdb.elc bbdb-com.el
bbdb-ftp.elc:        bbdb.elc bbdb-ftp.el
bbdb-gui.elc:		 bbdb.elc bbdb-gui.el
bbdb-merge.elc:      bbdb-merge.el
bbdb-migrate.elc:    bbdb.elc bbdb-migrate.el
bbdb-print.elc:      bbdb.elc bbdb-print.el
bbdb-snarf.elc:      bbdb.elc bbdb-snarf.el
bbdb-whois.elc:      bbdb.elc bbdb-whois.el
bbdb-w3.elc:         bbdb.elc bbdb-w3.el
bbdb-xemacs.elc:     bbdb.elc bbdb-xemacs.el

.el.elc:
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc -f batch-byte-compile $<

bbdb.elc:	bbdb.el
	@$(EMACS_PROG) -batch -q -f batch-byte-compile ./bbdb.el

bbdb-gnus.elc:	bbdb.elc bbdb-gnus.el
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc $(GNUS)   \
		-f batch-byte-compile $(@:.elc=.el)
bbdb-mhe.elc:	bbdb.elc bbdb-mhe.el
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc $(MHE)    \
		-f batch-byte-compile $(@:.elc=.el)
bbdb-rmail.elc:	bbdb.elc bbdb-rmail.el
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc $(RMAIL)  \
		-f batch-byte-compile $(@:.elc=.el)
bbdb-vm.elc:	bbdb.elc bbdb-vm.el
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc $(VM)     \
		-f batch-byte-compile $(@:.elc=.el)

bbdb-srv.elc:   bbdb.elc bbdb-srv.el
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc -eval '(progn (or (fboundp (quote define-obsolete-variable-alias)) (if (locate-library "gnuserv-compat") (load "gnuserv-compat" t t))) (if (and (locate-library "gnuserv") (locate-library "itimer")) (byte-compile-file "bbdb-srv.el") (message "Optional package bbdb-srv skipped - gnuserv not found")))'

bbdb-reportmail.elc: bbdb.elc bbdb-reportmail.el
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc -eval '(if (locate-library "reportmail") (byte-compile-file "bbdb-reportmail.el") (message "Optional package bbdb-reportmail skipped - reportmail not found"))'

bbdb-sc.elc: bbdb.elc bbdb-sc.el
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc -eval '(if (locate-library "supercite") (byte-compile-file "bbdb-sc.el") (message "Optional package bbdb-sc skipped - supercite not found"))'

# bbdb-hooks uses VM macros if it can find VM.

bbdb-hooks.elc:  bbdb.elc bbdb-hooks.el
	@$(EMACS_PROG) -batch -q $(PUSHPATH) -l ./bbdb.elc \
	-eval '(and (not (string= "$(VMDIR)" "")) \
		    (setq load-path (cons "$(VMDIR)" load-path)) \
		    (load "vm" t t) \
		    (load "vm-vars" t t))' \
	-f batch-byte-compile $(@:.elc=.el)

autoloads: bbdb-autoloads.el

autoloadsc: bbdb-autoloads.elc

extras: bbdb-print.elc bbdb-ftp.elc bbdb-whois.elc bbdb-xemacs.elc  \
	  bbdb-snarf.elc bbdb-w3.elc \
	bbdb-sc.elc bbdb-merge.elc bbdb-migrate.elc bbdb-gui.elc
bbdb:	bbdb.elc bbdb-com.elc bbdb-hooks.elc autoloadsc extras
rmail:	bbdb bbdb-rmail.elc
vm:	bbdb bbdb-vm.elc
mhe:	bbdb bbdb-mhe.elc
gnus:	bbdb bbdb-gnus.elc
# aliases
mh:	mhe
mh-e:	mhe

# Assorted clean-up targets
clean:
	-$(RM) bbdb*.elc

distclean: clean

# Backward compatibility
reallyclean: distclean

cvsclean: distclean
	-$(RM) bbdb-autoloads.el  # Generated file
	-$(RM) Makefile
