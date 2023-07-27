#!/bin/bash

set -x

cd ${SRC_DIR}

# gfortran 11.2.0 on osx-arm64 is buggy and causes a number of test failures.
# Setting a more generic set of instructions (armv8-a instead of armv8.3-a) ensures a proper compilation.
# This comes at the cost of some missed optimization.
if [[ "${target_platform}" == "osx-arm64" ]]; then
    export DEBUG_FFLAGS="${DEBUG_FFLAGS//armv8.3-a/armv8-a}"
    export DEBUG_FORTRANFLAGS="${DEBUG_FORTRANFLAGS//armv8.3-a/armv8-a}"
    export FFLAGS="${FFLAGS//armv8.3-a/armv8-a}"
    export FORTRANFLAGS="${FORTRANFLAGS//armv8.3-a/armv8-a}"
fi

if [[ ${blas_impl} == openblas ]]; then
    BLAS=openblas
    # Use OpenBLAS with 1 thread only as it seems to be using too many
    # on the CIs apparently.
    export OPENBLAS_NUM_THREADS=1
else
    BLAS=mkl-sdl
    # mkl-devel 2023.1.0 b0 is not packaged correctly...
    cp -r $PREFIX/mkl-devel/lib/* $PREFIX/lib/
fi

mkdir builddir
# -wnx flags mean: --wheel --no-isolation --skip-dependency-check
$PYTHON -m build -w -n -x \
    -Cbuilddir=builddir \
    -Csetup-args=-Dblas=${BLAS} \
    -Csetup-args=-Dlapack=${BLAS} \
    -Csetup-args=-Duse-g77-abi=true \
    -Csetup-args=-Duse-pythran=true \
    || (cat builddir/meson-logs/meson-log.txt && exit 1)
$PYTHON -m pip install dist/scipy*.whl