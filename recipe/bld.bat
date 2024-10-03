@echo on

REM Add a file to load the Fortran wrapper libraries in scipy/.libs
del scipy\_distributor_init.py
if %ERRORLEVEL% neq 0 exit 1
copy %RECIPE_DIR%\_distributor_init.py scipy\
if %ERRORLEVEL% neq 0 exit 1

REM Check if clang-cl is on path as required
clang-cl.exe --version
if %ERRORLEVEL% neq 0 exit 1

REM Set compilers to clang-cl
set "CC=clang-cl.exe"
set "CXX=clang-cl.exe"

REM Unset LDFLAGS; clang-cl & gfortran use different LDFLAGS
set "LDFLAGS="
REM Don't add d1trimfile option because clang doesn't recognize it.
set "SRC_DIR="

set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig;%BUILD_PREFIX%\Library\lib\pkgconfig"
if "%blas_impl%" == "openblas" (
    set "BLAS=openblas"
) else (
    set "BLAS=mkl-sdl"
)

mkdir builddir
REM Setting c++17. See: https://github.com/scipy/scipy/issues/19726
"%PYTHON%" -m build --wheel --no-isolation --skip-dependency-check ^
    -Cbuilddir=builddir ^
    -Csetup-args=-Dcpp_std=c++17 ^
    -Csetup-args=-Dblas=%BLAS% ^
    -Csetup-args=-Dlapack=%BLAS% ^
    -Csetup-args=-Duse-g77-abi=true ^
    -Csetup-args=-Duse-pythran=true ^
if errorlevel 1 (
  type builddir\meson-logs\meson-log.txt
  exit /b 1
)
for /f %%f in ('dir /b /S .\dist') do (
    pip install %%f
    if %ERRORLEVEL% neq 0 exit 1
)

REM After the build, check for the DLL
echo Checking for sf_error_state.dll
dir /s /b %PREFIX%\sf_error_state.dll
dir /s /b %PREFIX%\Lib\site-packages\scipy\special\sf_error_state.dll

REM Copy the DLL to the Library\bin directory if it exists
if exist %PREFIX%\Lib\site-packages\scipy\special\sf_error_state.dll (
    echo Copying sf_error_state.dll to Library\bin
    copy %PREFIX%\Lib\site-packages\scipy\special\sf_error_state.dll %PREFIX%\Library\bin\sf_error_state.dll
) else (
    echo sf_error_state.dll not found in the expected location
)

REM Final check
if exist %PREFIX%\Library\bin\sf_error_state.dll (
    echo sf_error_state.dll successfully copied to Library\bin
) else (
    echo Failed to copy sf_error_state.dll to Library\bin
    exit 1
)