@echo off

rem delayed expansion is needed to enable the !variable! syntax. https://ss64.com/nt/delayedexpansion.html
setlocal enabledelayedexpansion

set EXERCISE=%1

if [%EXERCISE%]==[] (
  echo This command will copy the provided tests into your exercises directory.
  echo USAGE: load_exercise.bat search string
  echo search string   A string that makes up all, or part, of the exercise name. Exercise numbers eg. 01 are the simplest form of search.
  echo WARNING:        RUNNING THIS COMMAND WILL OVERWRITE YOUR TESTS. IF YOU HAVE MADE CHANGES TO THE TESTS, YOU WILL LOSE THEM.
  rem exit /B 0
)

set SUB_FOLDERS=movr\rides\src\test\ movr\vehicles\src\test\ movr\users\src\test movr\ui_gateway\src\test

set SOLUTION_FOLDER=..\solutions

for /f %%i in ('dir %SOLUTION_FOLDER%\* /b ^| findstr %EXERCISE%') do (
    set EXERCISE_FOLDER=%SOLUTION_FOLDER%\%%i
)

if [!EXERCISE_FOLDER!]==[] (
  echo Unable to find a solution for the requested exercise: %EXERCISE%
  echo USAGE: load_exercise.bat search string
  exit /B 0
)

for %%f in (%SUB_FOLDERS%) do (
    set SOLUTION=!EXERCISE_FOLDER!\%%f
    set EXERCISE=%%f

    echo Loading Tests from !SOLUTION! to !EXERCISE!

    if not exist !SOLUTION!\ (
      echo WARNING: Unable to find tests for in the requested folder: !SOLUTION!...skipping
    )

    rmdir /s/q !EXERCISE!
    if not exist !EXERCISE! mkdir !EXERCISE!
    xcopy /s/q !SOLUTION!\* !EXERCISE!\ 1>NUL
)