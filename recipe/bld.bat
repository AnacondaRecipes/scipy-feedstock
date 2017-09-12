if errorlevel 1 exit 1

:: site.cfg unnecessary here; it is already baked into numpy

python setup.py install --single-version-externally-managed --record=record.txt
if errorlevel 1 exit 1
