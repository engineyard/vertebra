EXTRA_DIST = vertebra-rb vertebra-erl vertebra-gem natter

rake = cd $(srcdir)/$(1) && $(RAKE) $(2)

dist-hook: clean = rm -rf $(distdir)/$(1)/pkg $(distdir)/$(1)/.git*
dist-hook:
	$(call clean,vertebra-gem)
	$(call clean,vertebra-rb)
	$(call clean,vertebra-xen)
	$(call clean,vertebra-erl)
	$(call clean,natter)

.PHONY: vertebra-doc

.PHONY: install-vertebra-rb install-vertebra-gem

install-vertebra-rb:
	$(call rake,vertebra-rb,install)

install-vertebra-gem: install-vertebra-rb
	$(call rake,vertebra-gem,install)

install-data-local: install-vertebra-rb install-vertebra-gem

.PHONY: uninstall-vertebra-rb uninstall-vertebra-gem

uninstall-vertebra-rb:
	$(call rake,vertebra-rb,uninstall)

uninstall-vertebra-gem:
	$(call rake,vertebra-gem,uninstall)

uninstall-local: uninstall-vertebra-gem uninstall-vertebra-rb

.PHONY: ChangeLog
ChangeLog: OLD_VERSION=`git describe --abbrev=0`
ChangeLog:
	git log --no-merges $(OLD_VERSION)..HEAD > $(srcdir)/ChangeLog
