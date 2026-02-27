# Todo App 后端 API

使用 Flask + MySQL 的后端服务

## 环境要求

- Python 3.8+
- MySQL 5.7+

## 安装步骤

1. 安装依赖：
```bash
pip install -r requirements.txt
```

2. 配置数据库：
```bash
cp .env.example .env
# 编辑 .env 文件，填写你的 MySQL 配置
```

3. 创建数据库：
```sql
CREATE DATABASE todo_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

4. 启动服务：
```bash
python app.py
```

服务将在 http://localhost:5000 启动

## API 端点

### 健康检查
- `GET /health` - 检查服务状态

### 任务管理
- `GET /api/tasks` - 获取所有任务
- `GET /api/tasks/<id>` - 获取单个任务
- `POST /api/tasks` - 创建任务
- `PUT /api/tasks/<id>` - 更新任务
- `DELETE /api/tasks/<id>` - 删除任务

### 批量操作
- `DELETE /api/tasks/batch` - 批量删除任务
- `PUT /api/tasks/batch/status` - 批量更新完成状态
- `DELETE /api/tasks/completed` - 删除已完成任务

### 其他
- `GET /api/tasks/export` - 导出所有任务

## 请求示例

### 创建任务
```bash
curl -X POST http://localhost:5000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "完成项目",
    "description": "完成 Flutter 项目开发",
    "priority": 1,
    "category": 0
  }'
```

### 批量删除
```bash
curl -X DELETE http://localhost:5000/api/tasks/batch \
  -H "Content-Type: application/json" \
  -d '{"ids": [1, 2, 3]}'
```
