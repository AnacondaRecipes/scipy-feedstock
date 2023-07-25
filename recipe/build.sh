#!/bin/bash

set -x

cd ${SRC_DIR}

# Use OpenBLAS with 1 thread only as it seems to be using too many
# on the CIs apparently.
export OPENBLAS_NUM_THREADS=1

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
else
    BLAS=mkl
fi

$PYTHON -m pip install . --no-index --no-deps --no-build-isolation --ignore-installed --no-cache-dir -vv \
    --config-settings=setup-args="--prefix=${PREFIX}" \
    --config-settings=setup-args="-Dlibdir=lib" \
    --config-settings=setup-args="-Duse-g77-abi=true" \
    --config-settings=setup-args="-Duse-pythran=true" \
    --config-settings=setup-args="-Dblas=${BLAS}" \
    --config-settings=setup-args="-Dlapack=${BLAS}"