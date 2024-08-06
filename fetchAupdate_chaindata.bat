@echo off
setlocal enabledelayedexpansion

REM GitHub에서 파일 다운로드
set base_url=https://github.com/Gixist/FACT0RN_chaindata/raw/master
set file_prefix=factorn_backup_part
set part_ext=.zip.

REM 현재 디렉토리 설정
set current_dir=%cd%

REM 다운로드 및 파트 파일 목록 초기화
set part_number=1

REM 최대 999개의 파트 파일을 가정합니다.
:download_loop
REM 파트 번호를 세 자리 숫자로 포맷
set part_number_padded=00%part_number%
set part_number_padded=!part_number_padded:~-3!

set part_file=%current_dir%\%file_prefix%!part_ext!!part_number_padded!
set part_url=%base_url%/%file_prefix%!part_ext!!part_number_padded!
echo Downloading: !part_file!

REM HTTP 상태 코드를 변수로 설정
curl -s -o "!part_file!" -w "%%{http_code}" "!part_url!" > "%current_dir%\http_status.txt"
set /p http_status=<"%current_dir%\http_status.txt"

echo HTTP status code: %http_status%

REM HTTP 상태 코드 확인
if "%http_status%"=="200" (
    curl -L -o "!part_file!" "!part_url!"
    echo Download succeeded: !part_url!
    set /a part_number+=1
    goto download_loop
) else if "%http_status%"=="302" (
    curl -L -o "!part_file!" "!part_url!"
    echo Download succeeded: !part_url!
    set /a part_number+=1
    goto download_loop
) else (
    del !part_file!
    echo Failed to download or no more files: !part_url!
    goto :check_files
)

:check_files
REM 다운로드된 파일이 있는 경우만 작업 진행
set /a part_number-=1
if %part_number% leq 0 (
    echo Download failed: No files were downloaded.
    exit /b 1
)

REM Factorn 폴더가 없으면 생성합니다.
set appdata_folder=%appdata%\Factorn
if not exist "%appdata_folder%" (
    mkdir "%appdata_folder%"
)

REM 모든 분할 파일을 하나의 파일로 병합합니다.
REM 동적으로 모든 파트를 병합합니다.
set combined_zip="%current_dir%\combined.zip"
echo Combining split files...
del "%combined_zip%" 2>nul
for /L %%i in (1,1,%part_number%) do (
    set part_number_padded=00%%i
    set part_number_padded=!part_number_padded:~-3!
    set "current_part=%current_dir%\%file_prefix%!part_ext!!part_number_padded!"
    if exist "!current_part!" (
        if exist "%combined_zip%" (
            copy /b "%combined_zip%" + "!current_part!" >nul
        ) else (
            copy /b "!current_part!" "%combined_zip%" >nul
        )
    )
)

REM 병합된 ZIP 파일에서 temporary_archive.zip을 압축 해제합니다.
set temp_archive="%current_dir%\temporary_archive.zip"
echo Extracting temporary_archive.zip from combined.zip...
powershell -Command "Expand-Archive -Path '%combined_zip%' -DestinationPath '%current_dir%' -Force"

REM temporary_archive.zip을 압축 해제
powershell -Command "Expand-Archive -Path '%temp_archive%' -DestinationPath '%appdata_folder%' -Force"

REM 압축 해제 후 파일 및 임시 파일 삭제
del "%combined_zip%"
del "%temp_archive%"
del "%current_dir%\http_status.txt"


echo Extraction complete.