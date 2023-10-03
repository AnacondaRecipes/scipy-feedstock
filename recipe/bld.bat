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



REM switch between numpy.distutil build and meson build
if "%PY_VER%" == "3.12" goto :mesonbuild

REM Align numpy intel fortran compiler flags with what is expected by scipy.
REM Regarding /fp:strict and /assume:minus0 see: https://github.com/scipy/scipy/issues/17075 
REM Regarding /fpp The pre-processor flag is not enabled on older numpy.
powershell -Command "(gc %SP_DIR%\numpy\distutils\fcompiler\intel.py) -replace '''/nologo'', ', '''/nologo'', ''/fpp'', ''/fp:strict'', ''/assume:minus0'', ' | Out-File -encoding ASCII %SP_DIR%\numpy\distutils\fcompiler\intel.py"
if errorlevel 1 exit 1

COPY %PREFIX%\site.cfg site.cfg

REM Use the G77 ABI wrapper everywhere so that the underlying blas implementation
REM can have a G77 ABI (currently only MKL)
set SCIPY_USE_G77_ABI_WRAPPER=1

REM add %PREFIX%\include for inclusion of Python.h in linalg
set "INCLUDE=%INCLUDE%;%PREFIX%\include"

%PYTHON% _setup.py install --single-version-externally-managed --record=record.txt
if %ERRORLEVEL% neq 0 exit 1



:mesonbuild

set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig;%BUILD_PREFIX%\Library\lib\pkgconfig"
if "%blas_impl%" == "openblas" (
    set "BLAS=openblas"
)
else (
    set "BLAS=mkl-sdl"
)

mkdir builddir
"%PYTHON%" -m build --wheel --no-isolation --skip-dependency-check ^
    -Cbuilddir=builddir ^
    -Csetup-args=-Dblas=%BLAS% ^
    -Csetup-args=-Dlapack=%BLAS% ^
    -Csetup-args=-Duse-g77-abi=true ^
    -Csetup-args=-Duse-pythran=true
if errorlevel 1 (
  type builddir\meson-logs\meson-log.txt
  exit /b 1
)
for /f %%f in ('dir /b /S .\dist') do (
    pip install %%f
    if %ERRORLEVEL% neq 0 exit 1
)
