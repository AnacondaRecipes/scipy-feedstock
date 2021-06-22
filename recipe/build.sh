#!/bin/bash


# Use OpenBLAS with 1 thread only as it seems to be using too many
# on the CIs apparently.
export OPENBLAS_NUM_THREADS=1

# # Depending on our platform, shared libraries end with either .so or .dylib
if [[ $(uname) == 'Darwin' ]]; then
    export LDFLAGS="$LDFLAGS -undefined dynamic_lookup"
    export CFLAGS="$CFLAGS -fno-lto"
else
    export LDFLAGS="$LDFLAGS -shared"
fi

case $( uname -m ) in
aarch64) cp $PREFIX/aarch_site.cfg site.cfg;;
*)       cp $PREFIX/site.cfg site.cfg;;
esac

$PYTHON -m pip install . -vv
