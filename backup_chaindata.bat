@echo off
setlocal enabledelayedexpansion

REM Set the source directory path
set "SOURCE_DIR=%appdata%\Factorn"

REM Set files and directories to compress
set "FILES_TO_COMPRESS=blocks chainstate anchors.dat peers.dat"

REM Set temporary archive path
set "TEMP_ARCHIVE=%temp%\temporary_archive.zip"

REM Set split size (20MB) and file extension for split parts
set "SPLIT_SIZE=20m"
set "SPLIT_EXT=.zip"

REM Set the path where the archive will be saved
set "ARCHIVE_PATH=%cd%\factorn_backup"

REM Create temporary working directory
set "TEMP_DIR=%temp%\factorn_temp"
mkdir "%TEMP_DIR%"
echo Temporary directory created: %TEMP_DIR%

REM Copy files to the temporary directory
echo Copying files...
for %%f in (%FILES_TO_COMPRESS%) do (
    if exist "%SOURCE_DIR%\%%f" (
        echo Copying file %%f...
        if exist "%SOURCE_DIR%\%%f\*" (
            xcopy /s /e /I /Y "%SOURCE_DIR%\%%f" "%TEMP_DIR%\%%f" 
        ) else (
            copy /Y "%SOURCE_DIR%\%%f" "%TEMP_DIR%\%%f" 
        )
    ) else (
        echo File %%f does not exist in the source directory.
    )
)

REM Check if the temporary archive already exists and delete it
if exist "%TEMP_ARCHIVE%" (
    echo Temporary archive exists. Deleting...
    del "%TEMP_ARCHIVE%"
)

REM Create temporary archive file using 7-Zip with ZIP format
echo Creating ZIP archive...
7z a -tzip "%TEMP_ARCHIVE%" "%TEMP_DIR%\*"

REM Perform split compression using 7-Zip
echo Performing split compression...

REM Create the split archive
7z a -tzip -v%SPLIT_SIZE% "%ARCHIVE_PATH%_part%SPLIT_EXT%" "%TEMP_ARCHIVE%"

REM Check if split files are created and if so, clean up temporary archive
if exist "%TEMP_ARCHIVE%" (
    echo Temporary archive exists. Deleting...
    del "%TEMP_ARCHIVE%"
)

REM Delete temporary files
echo Deleting temporary files...
rmdir /s /q "%TEMP_DIR%"

echo All tasks are completed.
pause
