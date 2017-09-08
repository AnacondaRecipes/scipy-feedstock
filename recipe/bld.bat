if errorlevel 1 exit 1

:: bug in VS215 update 3 crashes with internal compiler error.  Advice from MS is to disable LTCG.
(
echo [ALL]
echo library_dirs = %LIBRARY_LIB%
echo include_dirs = %LIBRARY_INC%
) >> site.cfg


if "%c_compiler%" == "vs2015" (
echo extra_link_args = /LTCG:OFF >> site.cfg
)

if "%blas_impl%" == "mkl" (

(
echo [mkl]
echo mkl_libs = mkl_core_dll, mkl_intel_lp64_dll, mkl_intel_thread_dll
echo lapack_libs = mkl_scalapack_lp64_dll
) > site.cfg

) else (

(
echo [atlas]
echo atlas_libs = openblas
echo libraries = openblas
echo.
echo [openblas]
echo libraries = openblas
) > site.cfg

)

IF "%target_platform%" == "win-64" (
  set "fcompiler=intelem"
) else (
  set "fcompiler=intel"
)

python setup.py install --single-version-externally-managed --record=record.txt
if errorlevel 1 exit 1
