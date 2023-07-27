@echo on

REM Add a file to load the fortran wrapper libraries in scipy/.libs
del scipy\_distributor_init.py
if %ERRORLEVEL% neq 0 exit 1
copy %RECIPE_DIR%\_distributor_init.py scipy\
if %ERRORLEVEL% neq 0 exit 1

REM check if clang-cl is on path as required
clang-cl.exe --version
if %ERRORLEVEL% neq 0 exit 1

REM set compilers to clang-cl
set "CC=clang-cl.exe"
set "CXX=clang-cl.exe"

REM clang-cl & gfortran use different LDFLAGS; unset it
set "LDFLAGS="
REM don't add d1trimfile option because clang doesn't recognize it.
set "SRC_DIR="

if "%blas_impl%" == "openblas" (
    set "BLAS=openblas"
)
else (
    set "BLAS=mkl-sdl"
)
"%PYTHON%" -m pip install . --no-index --no-deps --no-build-isolation --ignore-installed --no-cache-dir -vv ^
    --config-settings=setup-args="-Duse-g77-abi=true" ^
    --config-settings=setup-args="-Duse-pythran=true" ^
    --config-settings=setup-args="-Dblas=%BLAS%" ^
    --config-settings=setup-args="-Dlapack=%BLAS%"
if %ERRORLEVEL% neq 0 exit 1

REM make sure these aren't packaged
del %LIBRARY_LIB%\blas.fobjects
del %LIBRARY_LIB%\blas.cobjects
del %LIBRARY_LIB%\cblas.fobjects
del %LIBRARY_LIB%\cblas.cobjects
del %LIBRARY_LIB%\lapack.fobjects
del %LIBRARY_LIB%\lapack.cobjects
