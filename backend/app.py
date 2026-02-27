"""
Todo App Backend API
使用 Flask 和 MySQL 实现的后端服务
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
from datetime import datetime
import os
from dotenv import load_dotenv

# 加载 .env 文件
load_dotenv()

app = Flask(__name__)
CORS(app)  # 允许跨域请求

# 数据库配置
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'todo_app'),
    'autocommit': True
}


def parse_due_date(due_date_value):
    """
    解析截止日期 - 支持多种格式
    - 毫秒时间戳 (整数)
    - ISO 字符串格式
    - None (返回 None)
    """
    if due_date_value is None:
        return None

    # 如果是毫秒时间戳 (整数)
    if isinstance(due_date_value, (int, float)) and due_date_value > 10000000000:
        try:
            dt = datetime.fromtimestamp(due_date_value / 1000)
            return dt.date()
        except (ValueError, OSError):
            return None

    # 如果是 ISO 字符串格式
    if isinstance(due_date_value, str):
        try:
            # 尝试解析 ISO 格式
            dt = datetime.fromisoformat(due_date_value.replace('Z', '+00:00'))
            return dt.date()
        except ValueError:
            return None

    return None


def get_db_connection():
    """获取数据库连接"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"数据库连接错误: {e}")
        return None


def init_db():
    """初始化数据库表"""
    # 先连接到 MySQL 服务器创建数据库（如果不存在）
    try:
        # 不指定数据库名称来连接
        connection_without_db = mysql.connector.connect(
            host=DB_CONFIG['host'],
            port=DB_CONFIG['port'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password']
        )
        cursor = connection_without_db.cursor()
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_CONFIG['database']} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
        cursor.close()
        connection_without_db.close()
        print(f"数据库 {DB_CONFIG['database']} 已就绪")
    except Error as e:
        print(f"创建数据库错误: {e}")
        return False

    connection = get_db_connection()
    if connection is None:
        return False

    try:
        cursor = connection.cursor()

        # 创建 tasks 表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id INT AUTO_INCREMENT PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT,
                is_completed TINYINT(1) DEFAULT 0,
                priority INT DEFAULT 1,
                category INT DEFAULT 4,
                due_date DATE,
                created_at BIGINT NOT NULL,
                updated_at BIGINT NOT NULL,
                user_id VARCHAR(255),
                INDEX idx_tasks_completed (is_completed),
                INDEX idx_tasks_priority (priority),
                INDEX idx_tasks_updated_at (updated_at)
            )
        ''')

        connection.commit()
        print("数据库初始化成功")
        return True
    except Error as e:
        print(f"数据库初始化错误: {e}")
        return False
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


# 健康检查
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok', 'message': 'Todo API is running'})


# 获取所有任务
@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    try:
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor(dictionary=True)

        # 获取查询参数
        is_completed = request.args.get('is_completed')
        priority = request.args.get('priority')
        search = request.args.get('search')

        query = 'SELECT * FROM tasks'
        params = []

        conditions = []
        if is_completed is not None:
            conditions.append('is_completed = %s')
            params.append(1 if is_completed.lower() == 'true' else 0)
        if priority is not None:
            conditions.append('priority = %s')
            params.append(int(priority))
        if search:
            conditions.append('(title LIKE %s OR description LIKE %s)')
            params.extend([f'%{search}%', f'%{search}%'])

        if conditions:
            query += ' WHERE ' + ' AND '.join(conditions)

        query += ' ORDER BY updated_at DESC'

        cursor.execute(query, params)
        tasks = cursor.fetchall()

        # 转换数据格式
        for task in tasks:
            task['is_completed'] = bool(task['is_completed'])
            if task['due_date']:
                task['due_date'] = task['due_date'].isoformat()

        cursor.close()
        connection.close()

        return jsonify(tasks)
    except Error as e:
        return jsonify({'error': str(e)}), 500


# 获取单个任务
@app.route('/api/tasks/<int:task_id>', methods=['GET'])
def get_task(task_id):
    try:
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor(dictionary=True)
        cursor.execute('SELECT * FROM tasks WHERE id = %s', (task_id,))
        task = cursor.fetchone()

        if task:
            task['is_completed'] = bool(task['is_completed'])
            if task['due_date']:
                task['due_date'] = task['due_date'].isoformat()

        cursor.close()
        connection.close()

        if task:
            return jsonify(task)
        return jsonify({'error': '任务不存在'}), 404
    except Error as e:
        return jsonify({'error': str(e)}), 500


# 创建任务
@app.route('/api/tasks', methods=['POST'])
def create_task():
    try:
        data = request.json
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor()

        now = int(datetime.now().timestamp() * 1000)

        # 解析截止日期
        due_date = parse_due_date(data.get('due_date'))

        query = '''
            INSERT INTO tasks (title, description, is_completed, priority, category, due_date, created_at, updated_at, user_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        '''
        params = (
            data.get('title'),
            data.get('description'),
            1 if data.get('is_completed') else 0,
            data.get('priority', 1),
            data.get('category', 4),
            due_date,
            now,
            now,
            data.get('user_id')
        )

        cursor.execute(query, params)
        task_id = cursor.lastrowid

        connection.commit()
        cursor.close()
        connection.close()

        return jsonify({'id': task_id, 'message': '任务创建成功'}), 201
    except Error as e:
        return jsonify({'error': str(e)}), 500


# 更新任务
@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    try:
        data = request.json
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor()

        # 构建更新语句
        update_fields = []
        params = []

        if 'title' in data:
            update_fields.append('title = %s')
            params.append(data['title'])
        if 'description' in data:
            update_fields.append('description = %s')
            params.append(data['description'])
        if 'is_completed' in data:
            update_fields.append('is_completed = %s')
            params.append(1 if data['is_completed'] else 0)
        if 'priority' in data:
            update_fields.append('priority = %s')
            params.append(data['priority'])
        if 'category' in data:
            update_fields.append('category = %s')
            params.append(data['category'])
        if 'due_date' in data:
            update_fields.append('due_date = %s')
            params.append(parse_due_date(data['due_date']))

        update_fields.append('updated_at = %s')
        params.append(int(datetime.now().timestamp() * 1000))

        params.append(task_id)

        query = f"UPDATE tasks SET {', '.join(update_fields)} WHERE id = %s"
        cursor.execute(query, params)

        connection.commit()
        cursor.close()
        connection.close()

        return jsonify({'message': '任务更新成功'})
    except Error as e:
        return jsonify({'error': str(e)}), 500


# 删除任务
@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    try:
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor()
        cursor.execute('DELETE FROM tasks WHERE id = %s', (task_id,))

        connection.commit()
        cursor.close()
        connection.close()

        return jsonify({'message': '任务删除成功'})
    except Error as e:
        return jsonify({'error': str(e)}), 500


# 批量删除任务
@app.route('/api/tasks/batch', methods=['DELETE'])
def batch_delete_tasks():
    try:
        data = request.json
        task_ids = data.get('ids', [])

        if not task_ids:
            return jsonify({'error': '没有提供要删除的任务 ID'}), 400

        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor()

        placeholders = ', '.join(['%s'] * len(task_ids))
        query = f'DELETE FROM tasks WHERE id IN ({placeholders})'
        cursor.execute(query, task_ids)

        connection.commit()
        cursor.close()
        connection.close()

        return jsonify({'message': f'已删除 {cursor.rowcount} 个任务'})
    except Error as e:
        return jsonify({'error': str(e)}), 500


# 批量更新完成状态
@app.route('/api/tasks/batch/status', methods=['PUT'])
def batch_update_status():
    try:
        data = request.json
        task_ids = data.get('ids', [])
        is_completed = data.get('is_completed', False)

        if not task_ids:
            return jsonify({'error': '没有提供要更新的任务 ID'}), 400

        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor()

        placeholders = ', '.join(['%s'] * len(task_ids))
        query = f'''
            UPDATE tasks SET is_completed = %s, updated_at = %s
            WHERE id IN ({placeholders})
        '''
        params = [1 if is_completed else 0, int(datetime.now().timestamp() * 1000)] + task_ids
        cursor.execute(query, params)

        connection.commit()
        cursor.close()
        connection.close()

        return jsonify({'message': f'已更新 {cursor.rowcount} 个任务'})
    except Error as e:
        return jsonify({'error': str(e)}), 500


# 删除已完成的任务
@app.route('/api/tasks/completed', methods=['DELETE'])
def delete_completed_tasks():
    try:
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor()
        cursor.execute('DELETE FROM tasks WHERE is_completed = 1')

        connection.commit()
        cursor.close()
        connection.close()

        return jsonify({'message': f'已删除 {cursor.rowcount} 个已完成的任务'})
    except Error as e:
        return jsonify({'error': str(e)}), 500


# 导出数据
@app.route('/api/tasks/export', methods=['GET'])
def export_tasks():
    try:
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': '数据库连接失败'}), 500

        cursor = connection.cursor(dictionary=True)
        cursor.execute('SELECT * FROM tasks ORDER BY updated_at DESC')
        tasks = cursor.fetchall()

        # 转换数据格式
        for task in tasks:
            task['is_completed'] = bool(task['is_completed'])
            if task['due_date']:
                task['due_date'] = task['due_date'].isoformat()

        cursor.close()
        connection.close()

        export_data = {
            'version': '1.0',
            'export_date': datetime.now().isoformat(),
            'tasks': tasks
        }

        return jsonify(export_data)
    except Error as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # 初始化数据库
    init_db()
    # 启动服务器
    app.run(host='0.0.0.0', port=5000, debug=True)
