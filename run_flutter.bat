@echo off
REM Flutter 应用启动脚本
REM 自动关闭之前的 Flutter 进程

echo 正在清理之前的 Flutter 进程...

REM 查找并关闭占用相关端口的进程
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080.*LISTENING"') do taskkill /F /PID %%a 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8081.*LISTENING"') do taskkill /F /PID %%a 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8082.*LISTENING"') do taskkill /F /PID %%a 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8888.*LISTENING"') do taskkill /F /PID %%a 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8989.*LISTENING"') do taskkill /F /PID %%a 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":9999.*LISTENING"') do taskkill /F /PID %%a 2>nul

echo 清理完成，正在启动 Flutter 应用...
cd /d "%~dp0"
flutter run -d chrome --web-port=8989

pause
