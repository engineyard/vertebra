SUBDIRS = natter vertebra-erl

rake = cd $(srcdir)/$(1) && $(RAKE) $(2)

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
