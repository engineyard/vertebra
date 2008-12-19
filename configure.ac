# -*- Autoconf -*-
AC_PREREQ(2.61)
AC_INIT(vertebra, 0.3.0)
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
#AC_CONFIG_SRCDIR([src/vertebractl.in])

# Erlang
AC_ERLANG_NEED_ERL
AC_ERLANG_NEED_ERLC

# Ruby
AC_ARG_VAR(RAKE, The path to the rake program)
AC_PATH_PROG(RAKE, rake)

# Output
AC_CONFIG_FILES([Makefile])
AC_CONFIG_SUBDIRS([natter vertebra-erl vertebra-doc])
AC_OUTPUT
