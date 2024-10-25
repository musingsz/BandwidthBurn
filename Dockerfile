# 使用官方的 Python 3.12 镜像作为基础镜像
FROM python:3.12-slim

# 设置工作目录
WORKDIR /app

# 复制当前目录下的 requirements.txt 文件到容器中
COPY requirements.txt requirements.txt

# 安装依赖包
RUN pip install --no-cache-dir -r requirements.txt

# 复制整个应用目录到容器中
COPY . .

# 在 Dockerfile 中设置脚本的执行权限
RUN chmod +x run.sh
# 设置环境变量
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# 暴露端口
EXPOSE 8212

# 启动命令
CMD ["./run.sh"]