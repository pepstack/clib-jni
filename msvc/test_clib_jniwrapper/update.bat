@ECHO OFF

if "%1" == "x64_debug" (
  set Platform=x64
  set Configuration=Debug
)


if "%1" == "x64_release" (
  set Platform=x64
  set Configuration=Release
)


if "%1" == "x86_debug" (
  set Platform=Win32
  set Configuration=Debug
)


if "%1" == "x86_release" (
  set Platform=Win32
  set Configuration=Release
)

set JNIWRAPPERLIB=%~dp0..\clib_jniwrapper\target\%Platform%\%Configuration%\clib_jniwrapper.dll
set DEPPROJECTLIB=%~dp0..\libclib_dll\target\%Platform%\%Configuration%\libclib_dll.dll

echo "%JNIWRAPPERLIB%"
echo "%DEPPROJECTLIB%"

copy "%DEPPROJECTLIB%" "%~dp0target\%Platform%\%Configuration%\"
copy "%JNIWRAPPERLIB%" "%~dp0target\%Platform%\%Configuration%\"