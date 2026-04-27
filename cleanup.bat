@echo off
echo ========================================
echo   Cleanup Script
echo ========================================
echo.

if exist "index.html.backup_20260422_v2" (
    del /f /q "index.html.backup_20260422_v2"
    echo [OK] deleted index.html.backup_20260422_v2
) else (
    echo [SKIP] index.html.backup_20260422_v2 not found
)

if exist "create_missing_tables.sql" (
    del /f /q "create_missing_tables.sql"
    echo [OK] deleted create_missing_tables.sql
) else (
    echo [SKIP] create_missing_tables.sql not found
)

for %%f in (*.backup*) do (
    del /f /q "%%f"
    echo [OK] deleted %%f
)

for %%f in (*.bak) do (
    del /f /q "%%f"
    echo [OK] deleted %%f
)

echo.
echo ----------------------------------------
echo   Creating backup...
echo ----------------------------------------
copy /y "index.html" "index.html.backup_20260422" >nul
echo [OK] created index.html.backup_20260422

echo.
echo ========================================
echo   Done! Files:
echo ========================================
echo.
dir /b
echo.
echo   Press any key to close...
pause >nul
