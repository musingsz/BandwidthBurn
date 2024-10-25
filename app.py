# app.py
from flask import Flask, render_template, request
import sqlite3
from flask_apscheduler import APScheduler
from apscheduler.schedulers.background import BackgroundScheduler
import time
import requests
import logging.config
from datetime import datetime

logging.config.fileConfig('logging.conf')

download_urls = [
    "https://store.storevideos.cdn-apple.com/v1/store.apple.com/st/1666383693478/atvloop-video-202210/streams_atvloop-video-202210/1920x1080/fileSequence3.m4s",
    "https://tbexpand.alicdn.com/aa4055d3f9094c2b/1632968880596/768716378c63550b.mp4_329682839911_mp4_264_hd.mp4?auth_key=1729768542-0-0-1eb21a9e4f620e755c0b15add6e2c2da&biz=publish-5036f53479b12226&t=0b51596117297658425333936e14fb&t=0b51596117297658425333936e14fb&b=publish&p=cloudvideo_http_video_extranet_publish&i=329682839911",
    "https://speed.cloudflare.com/__down?bytes=104857600",
    "https://cdn.akamai.steamstatic.com/steam/apps/1063730/extras/NW_Sword_Sorcery_2.gif",
    "https://dldir1.qq.com/qqfile/qq/QQNT/Windows/QQ_9.9.15_241009_x64_01.exe",
    "https://epicgames-download1.akamaized.net/Builds/UnrealEngineLauncher/Installers/Mac/EpicInstaller-15.17.1.dmg?launcherfilename=EpicInstaller-15.17.1.dmg",
    "https://hyp-webstatic.mihoyo.com/hyp-client/hyp_cn_setup_1.2.2.exe",
    "https://packages.vmware.com/tools/releases/latest/windows/VMware-tools-windows-arm-12.5.0-24276846.iso",
    "https://packages.vmware.com/tools/releases/12.5.0/windows/VMware-tools-windows-12.5.0-24276846.iso",
    "https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso",
    "https://repo1.maven.org/maven2/org/springframework/spring-webmvc/5.2.20.RELEASE/spring-webmvc-5.2.20.RELEASE-javadoc.jar",
    "https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso",
    "https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso.zsync",
    "https://xyq.gdl.netease.com/XYQDownloader.exe?key1=e1309fd78f062bdb6c21bcdc519d82f2&key2=671b8ac7",
    "https://downloader.battlenet.com.cn/download/getInstaller?os=mac&installer=Battle.net-Setup-CN.zip",
    "https://down.val.qq.com/dependencies/dxwebsetup.exe",
    "https://epicgames-download1.akamaized.net/Builds/UnrealEngineLauncher/Installers/Mac/EpicInstaller-15.17.1.dmg?launcherfilename=EpicInstaller-15.17.1.dmg",
    "blob:https://qqgame.qq.com/cfe895f9-dc15-4372-ad66-0d6d21b8b8e7",
    "https://dl1.wsyhn.com//fwqk123/3DM-YOUXIYUNXINGKU.v3.0.7z",
]
class Config(object):
    SCHEDULER_API_ENABLED = True
    SCHEDULER_EXECUTORS = {"default": {"type": "threadpool", "max_workers": 1}}


app = Flask(__name__)

scheduler = APScheduler(scheduler=BackgroundScheduler(timezone='Asia/Shanghai'))

app.config.from_object(Config())
scheduler.init_app(app)
scheduler.start()


# 数据库初始化
def init_db():
    conn = sqlite3.connect('data.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS downloads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT,
            total_downloaded REAL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()



@app.route('/')
def report():
    conn = sqlite3.connect('data.db')
    c = conn.cursor()
    
    # 查询每小时的下载总量
    c.execute('''
      SELECT strftime('%Y-%m-%d %H:00:00', timestamp) AS hour, SUM(total_downloaded) AS total_downloaded
        FROM downloads
        WHERE timestamp >= datetime('now', '-30 days')
        GROUP BY hour
        ORDER BY hour DESC
    ''')
    
    report_data_list = c.fetchall()
    # 查询月下载总量
    c.execute('''
  SELECT strftime('%Y-%m', timestamp) AS month, SUM(total_downloaded) AS total_downloaded
        FROM downloads
        WHERE timestamp >= datetime('now', '-12 months')
        GROUP BY month
        ORDER BY month DESC
    ''')
    total_data_list = c.fetchall()
    conn.close()
    
    return render_template('report_hours.html', report_data=report_data_list,total_data = total_data_list)


# 设置下载速率

# 全局变量来存储下载速率，默认设置为 500KB/s
current_speed_limit = 1  # 1024KB/s

@app.route('/set_speed', methods=['POST'])
def set_speed():
    global current_speed_limit
    speed_limit = request.form['speed_limit']
    try:
        # 将速率转换为浮点数（单位：MB/s）
        current_speed_limit = float(speed_limit)
        return "Speed limit set to {} MB/s".format(current_speed_limit)
    except ValueError:
        return "Invalid speed limit value", 400

# 流量统计报告

# 执行下载任务
def download_file(url):
    global current_speed_limit
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip, deflate, br',
        'DNT': '1',  # Do Not Track
        'Upgrade-Insecure-Requests': '1',
        'Cache-Control': 'max-age=0'
    }
    
    try:
        response = requests.get(url, headers=headers, stream=True)
        response.raise_for_status()  # 检查请求是否成功

        total_downloaded = 0

        for chunk in response.iter_content(chunk_size=8192):
            if current_speed_limit:
                # 将速率转换为字节（1MB = 1024 * 1024 bytes）
                speed_limit_bytes = current_speed_limit * 1024 * 1024
                time.sleep(len(chunk) / speed_limit_bytes)  # 控制下载速率
            total_downloaded += len(chunk)
        print(f"Downloaded {total_downloaded} bytes from {url}")
        store_download_stats(url, total_downloaded)
        return total_downloaded
    except Exception as e:
        store_download_stats(url, 0)
        print(f"Error downloading {url}: {e}")
        return 0

# 将下载统计信息存储到数据库
def store_download_stats(url,total_downloaded):
    logging.info(f"====>>store_download_stats:{url}")
    conn = sqlite3.connect('data.db')
    c = conn.cursor()
    c.execute('''INSERT INTO downloads (url, total_downloaded, timestamp) VALUES (?, ?, ?)''', (url, total_downloaded, datetime.now().strftime('%Y-%m-%d %H:%M:%S')))
    conn.commit()
    conn.close()

# 定时任务
@scheduler.task('interval', id='scheduled_task', seconds=60, misfire_grace_time=10,max_instances=1)
def scheduled_task():
    logging.info(f"=====================>scheduled_task<=====================")
    for url in download_urls:
        download_file(url)
        time.sleep(5)


def prod():
    init_db()
    return app

def dev():
    init_db()
    app.run(debug=True, host='0.0.0.0',port=9020)

if __name__ == "__main__":
    dev()