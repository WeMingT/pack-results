@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo     Result文件夹批量打包工具
echo ========================================
echo.

:: 检查是否安装了7-Zip
where 7z >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误：未找到7-Zip程序！
    echo 请安装7-Zip或确保7z.exe在PATH环境变量中。
    echo 下载地址：https://www.7-zip.org/
    pause
    exit /b 1
)

:: 获取当前目录
set "current_dir=%cd%"
echo 当前工作目录：%current_dir%
echo.

:: 创建输出目录
set "output_dir=%current_dir%\zip_output"
if not exist "%output_dir%" (
    mkdir "%output_dir%"
    echo 创建输出目录：%output_dir%
    echo.
)

:: 创建日志文件（使用简单的时间戳格式）
set "timestamp=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "timestamp=%timestamp: =0%"
set "log_file=%output_dir%\pack_log_%timestamp%.txt"

echo 开始打包操作 - %date% %time% > "%log_file%" 2>nul
if exist "%log_file%" (
    echo 工作目录: %current_dir% >> "%log_file%"
    echo 输出目录: %output_dir% >> "%log_file%"
    echo. >> "%log_file%"
    echo 日志文件已创建：%log_file%
) else (
    echo 警告：无法创建日志文件
)
echo.

:: 计数器
set /a total_folders=0
set /a success_count=0
set /a error_count=0

:: 遍历当前目录下的所有子文件夹（排除zip_output目录）
for /d %%i in (*) do (
    if /i not "%%i"=="zip_output" (
        set "folder_name=%%i"
        set "result_path=%%i\result"
        
        :: 检查是否存在result文件夹
        if exist "!result_path!" (
            set /a total_folders+=1
            echo [!total_folders!] 处理文件夹: !folder_name!
            
            :: 使用7z进行压缩，直接压缩result文件夹内的内容到zip文件根目录
            pushd "!result_path!" >nul 2>nul
            if !errorlevel! equ 0 (
                7z a -tzip "%output_dir%\!folder_name!.zip" * >nul 2>nul
                set zip_result=!errorlevel!
                popd >nul 2>nul
                  if !zip_result! equ 0 (
                    set /a success_count+=1
                    if exist "%log_file%" echo [成功] !folder_name! - %date% %time% >> "%log_file%"
                ) else (
                    echo     -> 打包失败
                    set /a error_count+=1
                    if exist "%log_file%" echo [失败] !folder_name! - %date% %time% >> "%log_file%"
                )
            ) else (
                echo     -> 无法访问目录
                set /a error_count+=1
                if exist "%log_file%" echo [失败] !folder_name! - 无法访问目录 - %date% %time% >> "%log_file%"
            )
            echo.
        ) else (
            echo [跳过] !folder_name! - 未找到result文件夹
            if exist "%log_file%" echo [跳过] !folder_name! - 未找到result文件夹 - %date% %time% >> "%log_file%"
            echo.
        )
    )
)

:: 显示统计结果
echo ========================================
echo           处理完成统计
echo ========================================
echo 总共检查文件夹数: %total_folders%
echo 成功打包: %success_count%个
echo 失败: %error_count%个
echo 输出目录: %output_dir%
if exist "%log_file%" echo 日志文件: %log_file%
echo.

:: 写入日志文件总结
if exist "%log_file%" (
    echo. >> "%log_file%"
    echo ===== 打包完成统计 ===== >> "%log_file%"
    echo 总共检查文件夹数: %total_folders% >> "%log_file%"
    echo 成功打包: %success_count%个 >> "%log_file%"
    echo 失败: %error_count%个 >> "%log_file%"
    echo 完成时间: %date% %time% >> "%log_file%"
)

if %total_folders% equ 0 (
    echo 注意：当前目录下没有找到包含result文件夹的子目录。
    echo 请确保：
    echo 1. 在正确的父目录中运行此脚本
    echo 2. 子文件夹中确实存在名为"result"的文件夹
)

echo 按任意键退出...
pause >nul