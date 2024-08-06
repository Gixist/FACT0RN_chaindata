# Factorn Backup and Restore

이 문서에서는 Factorn 프로그램의 백업과 복원을 위해 사용되는 두 개의 배치 파일 스크립트에 대해 설명합니다. 하나는 Factorn 데이터를 압축하고 분할하여 백업하는 스크립트이며, 다른 하나는 백업 파일을 다운로드하고 복원하는 스크립트입니다.

## 1\. 백업 스크립트 \(`backup_chaindata.bat`)

이 스크립트는 Factorn 데이터의 체인 상태를 백업하기 위한 스크립트입니다.

#### 기능

* Factorn 데이터 디렉토리에서 파일을 임시 디렉토리로 복사
* 복사된 파일을 ZIP 형식으로 압축
* 압축된 파일을 지정된 크기(예: 20MB)로 분할
* 사용된 임시 파일과 디렉토리 삭제

#### 사용 방법

1. 스크립트를 `backup_chaindata.bat` 파일로 저장
2. 7-Zip 설치 (공식 웹사이트에서 다운로드 및 설치)
3. `backup_chaindata.bat` 파일 실행 (더블 클릭 또는 명령 프롬프트에서 실행)

#### 스크립트

```
batch코드 복사@echo off
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
```

### 2\. 복원 스크립트 \(`fetchAupdate_chaindata.bat`)

이 스크립트는 GitHub에서 체인 데이터 파일을 다운로드하고 복원합니다.

#### 기능

* GitHub에서 백업된 파일을 다운로드
* 다운로드한 파일을 결합하여 ZIP 파일 생성
* PowerShell을 사용하여 ZIP 파일 복원

#### 사용 방법

1. 스크립트를 `fetchAupdate_chaindata.bat` 파일로 저장
2. 스크립트 실행 (더블 클릭 또는 명령 프롬프트에서 실행)

#### 스크립트

```
batch코드 복사@echo off
setlocal enabledelayedexpansion

REM GitHub에서 파일 다운로드
set base_url=https://github.com/username/repository/releases/latest/download
set file_prefix=factorn_backup_part.zip

REM 임시 디렉토리 설정
set temp_dir=%temp%\factorn_download
mkdir "%temp_dir%"

REM 다운로드 및 파트 파일 목록 초기화
set part_number=1
set part_file="%temp_dir%\%file_prefix%.%03d"

REM 최대 999개의 파트 파일을 가정합니다.
:download_loop
set part_file=%temp_dir%\%file_prefix%.%03d
set file_part=%file_prefix%.%03d
set part_url=%base_url%/%file_prefix%.%03d
echo Downloading: !file_part!

REM 각 파트 파일을 다운로드
curl -L -o "!part_file!" "!part_url!"

REM 다운로드가 완료되었는지 확인합니다.
if exist "!part_file!" (
    set /a part_number+=1
    goto download_loop
)

REM 다운로드된 파일이 있는 경우만 작업 진행
if %part_number% leq 1 (
    echo Download failed: No files were downloaded.
    exit /b 1
)

REM Factorn 폴더가 없으면 생성합니다.
set appdata_folder=%appdata%\Factorn
if not exist "%appdata_folder%" (
    mkdir "%appdata_folder%"
)

REM 모든 분할 파일을 하나의 파일로 병합합니다.
set combined_zip="%temp_dir%\combined.zip"
del "%combined_zip%" 2>nul
for /L %%i in (1,1,%part_number%) do (
    set part_number_padded=00%%i
    set part_number_padded=!part_number_padded:~-3!
    set "current_part=%temp_dir%\%file_prefix%!part_ext!!part_number_padded!"
    if exist "!current_part!" (
        if exist "%combined_zip%" (
            copy /b "%combined_zip%" + "!current_part!" >nul
        ) else (
            copy /b "!current_part!" "%combined_zip%" >nul
        )
    )
)

REM 병합된 ZIP 파일에서 temporary_archive.zip을 압축 해제합니다.
set temp_archive="%temp_dir%\temporary_archive.zip"
echo Extracting temporary_archive.zip from combined.zip...
powershell -Command "Expand-Archive -Path '%combined_zip%' -DestinationPath '%temp_dir%' -Force"

REM temporary_archive.zip을 압축 해제
powershell -Command "Expand-Archive -Path '%temp_archive%' -DestinationPath '%appdata_folder%' -Force"

REM 압축 해제 후 파일 및 임시 파일 삭제
del "%combined_zip%"
del "%temp_archive%"
rmdir /s /q "%temp_dir%"

echo Extraction complete.
pause
```

### 주의 사항

* 두 스크립트 모두 7-Zip과 PowerShell이 필요합니다.
* `fetchAupdate_chaindata.bat` 파일을 실행하기 전에 GitHub에서 사용하는 URL과 파일 이름을 적절히 설정해야 합니다.
* 백업 및 복원 과정에서 중요한 데이터를 다루기 때문에, 실제 환경에서 사용하기 전에 충분한 테스트가 필요합니다.

### 전체 요약

* **백업 스크립트 (`backup_chaindata.bat`)**: Factorn 데이터를 압축하고 지정된 크기로 분할하여 백업합니다.
* **복원 스크립트 (`fetchAupdate_chaindata.bat`)**: GitHub에서 백업된 파일을 다운로드하고, ZIP 파일로 복원합니다.
* 두 스크립트 모두 7-Zip과 PowerShell을 사용하며, 사용 전에 충분한 테스트가 필요합니다.