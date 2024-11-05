#!/bin/bash

# 日志文件
logfile="/tmp/speedtest.log"
dslogfile="/tmp/ds.log"

urls=(
    "https://store.storevideos.cdn-apple.com/v1/store.apple.com/st/1666383693478/atvloop-video-202210/streams_atvloop-video-202210/1920x1080/fileSequence3.m4s"
    "https://tbexpand.alicdn.com/aa4055d3f9094c2b/1632968880596/768716378c63550b.mp4_329682839911_mp4_264_hd.mp4?auth_key=1729768542-0-0-1eb21a9e4f620e755c0b15add6e2c2da&biz=publish-5036f53479b12226&t=0b51596117297658425333936e14fb&t=0b51596117297658425333936e14fb&b=publish&p=cloudvideo_http_video_extranet_publish&i=329682839911"
    "https://speed.cloudflare.com/__down?bytes=104857600"
    "https://cdn.akamai.steamstatic.com/steam/apps/1063730/extras/NW_Sword_Sorcery_2.gif"
    "https://dldir1.qq.com/qqfile/qq/QQNT/Windows/QQ_9.9.15_241009_x64_01.exe"
    "https://epicgames-download1.akamaized.net/Builds/UnrealEngineLauncher/Installers/Mac/EpicInstaller-15.17.1.dmg?launcherfilename=EpicInstaller-15.17.1.dmg"
    "https://hyp-webstatic.mihoyo.com/hyp-client/hyp_cn_setup_1.2.2.exe"
    "https://packages.vmware.com/tools/releases/latest/windows/VMware-tools-windows-arm-12.5.0-24276846.iso"
    "https://packages.vmware.com/tools/releases/12.5.0/windows/VMware-tools-windows-12.5.0-24276846.iso"
    "https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
    "https://repo1.maven.org/maven2/org/springframework/spring-webmvc/5.2.20.RELEASE/spring-webmvc-5.2.20.RELEASE-javadoc.jar"
    "https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso"
    "https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso.zsync"
    "https://xyq.gdl.netease.com/XYQDownloader.exe?key1=e1309fd78f062bdb6c21bcdc519d82f2&key2=671b8ac7"
    "https://downloader.battlenet.com.cn/download/getInstaller?os=mac&installer=Battle.net-Setup-CN.zip"
    "https://down.val.qq.com/dependencies/dxwebsetup.exe"
    "https://epicgames-download1.akamaized.net/Builds/UnrealEngineLauncher/Installers/Mac/EpicInstaller-15.17.1.dmg?launcherfilename=EpicInstaller-15.17.1.dmg"
    "blob:https://qqgame.qq.com/cfe895f9-dc15-4372-ad66-0d6d21b8b8e7"
    "https://dl1.wsyhn.com//fwqk123/3DM-YOUXIYUNXINGKU.v3.0.7z"
 )
total_bytes=0

# 模拟浏览器信息
user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
accept="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
accept_language="en-US,en;q=0.9"

# 循环遍历每个URL
for url in "${urls[@]}"; do
  echo "$(date +"%Y-%m-%d %H:%M:%S") 测试URL: $url" >> "$logfile"

  # 使用wget下载文件，显示进度，并模拟浏览器
  wget --user-agent="$user_agent" --header="Accept: $accept" --header="Accept-Language: $accept_language" -O /dev/null "$url" 2>&1 | tee -a "$logfile"

  # 获取下载大小 (wget 不直接提供已下载字节数，只能通过文件大小来近似)
  # 这里假设下载成功，否则 total_bytes 会不准确
  download_size=$(stat -c%s /dev/null) # 这里需要改进，获取实际下载大小
  if [[ -z "$download_size" ]]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") 获取文件大小失败: $url" >> "$logfile"
    continue
  fi

  total_bytes=$((total_bytes + download_size))

  echo ""
  sleep 5 # 在测试下一个URL之前等待5秒
done

# 计算总下载数据量 (GB) 并记录到 ds.log
total_gb=$(echo "scale=2; $total_bytes / 1024 / 1024 / 1024" | bc)
echo "$(date +"%Y-%m-%d %H:%M:%S") 总下载数据量: $total_gb GB" >> "$dslogfile"

echo "$(date +"%Y-%m-%d %H:%M:%S") 测试完成" >> "$logfile"