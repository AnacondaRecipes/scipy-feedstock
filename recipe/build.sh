#!/bin/bash

set -x

cd ${SRC_DIR}

# Use OpenBLAS with 1 thread only as it seems to be using too many
# on the CIs apparently.
export OPENBLAS_NUM_THREADS=1

# Depending on our platform, shared libraries end with either .so or .dylib
if [[ $(uname) == 'Darwin' ]]; then
    export LDFLAGS="$LDFLAGS -undefined dynamic_lookup"
    export CFLAGS="$CFLAGS -fno-lto"
else
    export LDFLAGS="$LDFLAGS -shared"
fi

# gfortran 11.2.0 on osx-arm64 is buggy and causes a number of test failures.
# Setting a more generic set of instructions (armv8-a instead of armv8.3-a) ensures a proper compilation.
# This comes at the cost of some missed optimization.
if [[ "${target_platform}" == "osx-arm64" ]]; then
    export DEBUG_FFLAGS="${DEBUG_FFLAGS//armv8.3-a/armv8-a}"
    export DEBUG_FORTRANFLAGS="${DEBUG_FORTRANFLAGS//armv8.3-a/armv8-a}"
    export FFLAGS="${FFLAGS//armv8.3-a/armv8-a}"
    export FORTRANFLAGS="${FORTRANFLAGS//armv8.3-a/armv8-a}"
fi

case $( uname -m ) in
# todo: update once ArmPL is ready.
# We should look to include copy aarch_site.cfg in the ArmPL package, similar
# to how OpenBLAS and MKL devels work. 
# aarch64) cp $PREFIX/aarch_site.cfg site.cfg;;
*)       cp $PREFIX/site.cfg site.cfg;;
esac

if [[ ${blas_impl} == openblas ]]; then
    BLAS=openblas
else
    BLAS=mkl
fi
$PYTHON -m pip install . --no-index --no-deps --no-build-isolation --ignore-installed --no-cache-dir -vv \
    --config-settings=setup-args="-Duse-g77-abi=true" \
    --config-settings=setup-args="-Duse-pythran=true" \
    --config-settings=setup-args="-Dblas=${BLAS}" \
    --config-settings=setup-args="-Dlapack=${BLAS}"