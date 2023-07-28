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
set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig;%BUILD_PREFIX%\Library\lib\pkgconfig"

mkdir builddir
REM -wnx flags mean: --wheel --no-isolation --skip-dependency-check
"%PYTHON%" -m build -w -n -x ^
    -Cbuilddir=builddir ^
    -Csetup-args=-Dblas=%BLAS% ^
    -Csetup-args=-Dlapack=%BLAS% ^
    -Csetup-args=-Duse-g77-abi=true ^
    -Csetup-args=-Duse-pythran=true
if errorlevel 1 (
  type builddir\meson-logs\meson-log.txt
  exit /b 1
)
"%PYTHON%" -m pip install dist/scipy*.whl
if %ERRORLEVEL% neq 0 exit 1

REM make sure these aren't packaged
del %LIBRARY_LIB%\blas.fobjects
del %LIBRARY_LIB%\blas.cobjects
del %LIBRARY_LIB%\cblas.fobjects
del %LIBRARY_LIB%\cblas.cobjects
del %LIBRARY_LIB%\lapack.fobjects
del %LIBRARY_LIB%\lapack.cobjects
