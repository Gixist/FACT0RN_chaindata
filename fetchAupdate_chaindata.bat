@echo off
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
copy /b %temp_dir%\%file_prefix%.001 + %temp_dir%\%file_prefix%.002 + %temp_dir%\%file_prefix%.003 + %temp_dir%\%file_prefix%.004 "%combined_zip%"

REM PowerShell을 사용하여 압축 해제
powershell -Command "Expand-Archive -Path '%combined_zip%' -DestinationPath '%appdata_folder%' -Force"

REM 압축 해제 후 파일 및 임시 디렉토리 삭제
del "%combined_zip%"
rmdir /s /q "%temp_dir%"

echo Extraction complete.
pause
