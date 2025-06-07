@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ========================================
echo     Result文件夹批量打包工具
echo ========================================
echo.

:: 检查是否安装了7-Zip
echo 正在检查7-Zip是否安装...
where 7z >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo 错误：未找到7-Zip程序！
    echo 请安装7-Zip或确保7z.exe在PATH环境变量中。
    echo 下载地址：https://www.7-zip.org/
    echo.
    pause
    exit /b 1
)
echo 7-Zip检查通过。
echo.

:: 获取当前目录
set "current_dir=%cd%"
echo 当前工作目录：%current_dir%
echo.

:: 创建输出目录
echo 正在准备输出目录...
set "output_dir=%current_dir%\zip_output"
if not exist "%output_dir%" (
    mkdir "%output_dir%"
    echo "已创建输出目录：%output_dir%"
) else (
    echo "输出目录已存在：%output_dir%"
)
echo.

:: 创建日志文件（使用新的时间戳格式 YYYY-MM-DD_HH-MM-SS）
set "timestamp=%date:~0,4%-%date:~5,2%-%date:~8,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "timestamp=%timestamp: =0%"
set "log_file=%output_dir%\pack_log_%timestamp%.txt"

echo 准备写入日志文件...
echo 开始打包操作 - %date% %time% > "%log_file%" 2>nul
if exist "%log_file%" (
    echo "工作目录: %current_dir%" >> "%log_file%"
    echo "输出目录: %output_dir%" >> "%log_file%"
    echo. >> "%log_file%"
    echo "日志文件已创建：%log_file%"
) else (
    echo 警告：无法创建日志文件。打包过程仍将继续，但不会记录日志。
)
echo.
echo ========================================
echo           开始处理文件夹
echo ========================================
echo.

:: 计数器
set /a total_folders_checked=0
set /a success_count=0
set /a error_count=0
set /a skipped_count=0

:: 遍历当前目录下的所有子文件夹（排除zip_output目录）
for /d %%i in (*) do (
    if /i not "%%i"=="zip_output" (
        set "folder_name=%%i"
        set "result_path=%%i\result"
        set /a total_folders_checked+=1
        
        echo ----------------------------------------
        echo 正在检查文件夹: "!folder_name!"
        
        :: 检查是否存在result文件夹
        if exist "!result_path!" (
            echo "  -> 找到result文件夹，准备打包..."
            
            :: 使用7z进行压缩，直接压缩result文件夹内的内容到zip文件根目录
            pushd "!result_path!" >nul 2>nul
            if !errorlevel! equ 0 (
                echo "  -> 正在压缩: %output_dir%\!folder_name!.zip"
                7z a -tzip "%output_dir%\!folder_name!.zip" * >nul 2>nul
                set zip_result=!errorlevel!
                popd >nul 2>nul
                if !zip_result! equ 0 (
                    echo "  -> [成功] 打包完成: !folder_name!.zip"
                    set /a success_count+=1
                    if exist "%log_file%" echo "[成功] !folder_name! - %date% %time%" >> "%log_file%"
                ) else (
                    echo "  -> [失败] 打包文件夹时出错: !folder_name!"
                    set /a error_count+=1
                    if exist "%log_file%" echo "[失败] !folder_name! - 打包错误 - %date% %time%" >> "%log_file%"
                )
            ) else (
                echo "  -> [失败] 无法访问result子目录: !result_path!"
                set /a error_count+=1
                if exist "%log_file%" echo "[失败] !folder_name! - 无法访问result目录 - %date% %time%" >> "%log_file%"
            )
        ) else (
            echo "  -> [跳过] 未找到result文件夹在: !folder_name!"
            set /a skipped_count+=1
            if exist "%log_file%" echo "[跳过] !folder_name! - 未找到result文件夹 - %date% %time%" >> "%log_file%"
        )
        echo.
    )
)
echo ----------------------------------------
echo.
:: 显示统计结果
echo ========================================
echo           处理完成统计
echo ========================================
echo 总共检查文件夹数: %total_folders_checked%
echo 成功打包: %success_count%个
echo 失败: %error_count%个
echo 跳过 (无result文件夹): %skipped_count%个
echo.
echo "输出目录: %output_dir%"
if exist "%log_file%" echo "日志文件: %log_file%"
echo.

:: 写入日志文件总结
if exist "%log_file%" (
    echo. >> "%log_file%"
    echo ===== 打包完成统计 ===== >> "%log_file%"
    echo 总共检查文件夹数: %total_folders_checked% >> "%log_file%"
    echo 成功打包: %success_count%个 >> "%log_file%"
    echo 失败: %error_count%个 >> "%log_file%"
    echo 跳过 (无result文件夹): %skipped_count%个 >> "%log_file%"
    echo 完成时间: %date% %time% >> "%log_file%"
)

if %success_count% equ 0 and %error_count% equ 0 and %skipped_count% equ %total_folders_checked% and %total_folders_checked% gtr 0 (
    echo 注意：已检查 %total_folders_checked% 个文件夹，但均未找到名为 "result" 的子文件夹。
    echo 请确保：
    echo 1. 您在正确的父目录中运行此脚本。
    echo 2. 目标子文件夹中确实存在名为 "result" 的文件夹 (区分大小写)。
    echo.
) else if %total_folders_checked% equ 0 (
    echo 注意：当前目录下没有找到任何子文件夹（已排除 "zip_output"）。
    echo 请确保您在包含项目子文件夹的父目录中运行此脚本。
    echo.
)


echo 按任意键退出...
pause >nul