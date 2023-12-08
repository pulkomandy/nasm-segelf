#!/bin/sh -x
#
# Run this script to regenerate autoconf files
#
recheck=false
if [ x"$1" = x--recheck ]; then
    recheck=true
    config=$(sh config.status --config 2>/dev/null)
fi

# This allows for overriding the default autoconf programs
AUTOCONF="${AUTOCONF:-${AUTOTOOLS_PREFIX}autoconf}"
AUTOMAKE="${AUTOMAKE:-${AUTOTOOLS_PREFIX}automake}"
ACLOCAL="${ACLOCAL:-${AUTOTOOLS_PREFIX}aclocal}"
AUTOHEADER="${AUTOHEADER:-${AUTOTOOLS_PREFIX}autoheader}"

mkdir -p autoconf autoconf/helpers config
autolib="`"$AUTOMAKE" --print-libdir`"
if test ! x"$autolib" = x; then
    for prg in install-sh compile config.guess config.sub; do
	# Update autoconf helpers if and only if newer ones are available
	if test -f "$autolib"/"$prg" && \
		( set -e ; \
		  test -f autoconf/helpers/"$prg" && sed -n \
		    -e 's/^scriptver=/scriptversion=/' \
		    -e 's/^timestamp=/scriptversion=/' \
		    -e 's/^scriptversion=['\''"]?\([^'\''"]*\).*$/\1/p' \
			  "$autolib"/"$prg" autoconf/helpers/"$prg" | \
			  sort -c 2>/dev/null ; \
		  test $? -ne 0 )
	then
	    cp -f "$autolib"/"$prg" autoconf/helpers
	fi
    done
fi
#mv -f autoconf/aclocal.m4 autoconf/aclocal.m4.old
#mkdir -p autoconf/m4.old autoconf/m4
#mv -f autoconf/m4/*.m4 autoconf/m4.old/ 2>/dev/null || true
#ACLOCAL_PATH="${ACLOCAL_PATH}${ACLOCAL_PATH:+:}`pwd`/autoconf/m4.old"
#export ACLOCAL_PATH
"$ACLOCAL" -I autoconf/m4
#if test ! -f autoconf/aclocal.m4; then
    # aclocal failed, revert to previous files
#    mv -f autoconf/m4.old/*.m4 autoconf/m4/
#    mv -f autoconf/aclocal.m4.old autoconf/aclocal.m4
#fi
#rm -rf autoconf/*m4.old
"$AUTOHEADER" -B autoconf
"$AUTOCONF" -B autoconf
(
    echo '#!/bin/sh'
    "$AUTOCONF" -B autoconf \
		-t AC_CONFIG_HEADERS:'rm -f $*' \
		-t AC_CONFIG_FILES:'rm -f $*'
    echo 'rm -f config.log config.status'
    echo 'rm -rf autom4te.cache'
) > /tmp/clean.sh
sh /tmp/clean.sh

# Try to regenerate unconfig.h if Perl is available and unconfig.pl
# is present in the autoconf directory.
#if [ -n "$(which perl)" -a -f autoconf/unconfig.pl ]; then
#    perl autoconf/unconfig.pl . config/config.h.in config/unconfig.h
#fi

if $recheck; then
    # This bizarre statement has to do with how config.status quotes its output
    echo exec sh configure $config | sh -
fi
