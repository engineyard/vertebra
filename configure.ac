# -*- Autoconf -*-
AC_PREREQ(2.61)
AC_INIT(vertebra, 0.4.0)
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
#AC_CONFIG_SRCDIR([src/vertebractl.in])

# Erlang
AC_ERLANG_NEED_ERL
AC_ERLANG_NEED_ERLC

# Ruby
AC_ARG_VAR(RAKE, The path to the rake program)
AC_PATH_PROG(RAKE, rake)

# Output
AC_ARG_ENABLE(doc, AC_HELP_STRING([--enable-doc], [configure vertebra-doc]),
              [if test "$enable_doc" != no; then
                 AC_CONFIG_SUBDIRS([vertebra-doc])
               fi])
AC_CONFIG_FILES([Makefile])
AC_CONFIG_SUBDIRS([natter vertebra-erl])
AC_OUTPUT
