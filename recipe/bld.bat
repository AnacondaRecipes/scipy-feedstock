if "%blas_impl%" == "mkl" (

(
echo [mkl]
echo library_dirs = %LIBRARY_LIB%
echo include_dirs = %LIBRARY_INC%
echo mkl_libs = mkl_core_dll, mkl_intel_lp64_dll, mkl_intel_thread_dll
echo lapack_libs = mkl_lapack95_lp64
) > site.cfg

) else (

(
echo [DEFAULT]
echo library_dirs = %LIBRARY_LIB%
echo include_dirs = %LIBRARY_INC%
echo.
echo [atlas]
echo atlas_libs = openblas
echo libraries = openblas
echo.
echo [openblas]
echo libraries = openblas
echo library_dirs = %LIBRARY_LIB%
echo include_dirs = %LIBRARY_INC%
) > site.cfg

)

IF "%target_platform%" == "win-64" (
  set "fcompiler=intelem"
) else (
  set "fcompiler=intel"
)

python setup.py config --fcompiler=%fcompiler% build_clib --fcompiler=intelem build_ext --fcompiler=intelem install
if errorlevel 1 exit 1
