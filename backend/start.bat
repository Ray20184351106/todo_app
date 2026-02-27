@echo off
REM Todo App Backend 启动脚本

echo ========================================
echo Todo App Backend API
echo ========================================
echo.

REM 检查 Python 是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 Python，请先安装 Python 3.8+
    pause
    exit /b 1
)

REM 检查虚拟环境
if not exist "venv" (
    echo [信息] 创建虚拟环境...
    python -m venv venv
)

REM 激活虚拟环境
echo [信息] 激活虚拟环境...
call venv\Scripts\activate.bat

REM 安装依赖
echo [信息] 安装依赖...
pip install -r requirements.txt

REM 检查 .env 文件
if not exist ".env" (
    echo.
    echo [警告] 未找到 .env 文件！
    echo 请先创建 .env 文件并配置数据库连接信息：
    echo   DB_HOST=localhost
    echo   DB_PORT=3306
    echo   DB_USER=root
    echo   DB_PASSWORD=your_password
    echo   DB_NAME=todo_app
    echo.
    pause
    exit /b 1
)

REM 启动服务器
echo.
echo [信息] 启动 API 服务器...
echo API 地址: http://localhost:5000
echo.
python app.py

pause
