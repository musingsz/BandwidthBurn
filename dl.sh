#!/bin/bash

# Define log file paths
DETAIL_LOG="download_detail.log"
SUMMARY_LOG="download_summary.log"

# Function: convert bytes to GB
bytes_to_gb() {
    if [ "$1" -eq 0 ]; then
        echo "0.000"
    else
        echo "$1" | awk '{printf "%.3f", $1 / (1024 * 1024 * 1024)}'
    fi
}

# Function: convert bytes/sec to MB/sec
bytes_to_mb_per_sec() {
    if [ "$1" -eq 0 ]; then
        echo "0.00"
    else
        echo "$1" | awk '{printf "%.2f", $1 / (1024 * 1024)}'
    fi
}

# Function: convert bytes to MB, keep integer
bytes_to_mb() {
    if [ "$1" -eq 0 ]; then
        echo "0"
    else
        echo "$1" | awk '{printf "%.0f", $1 / (1024 * 1024)}'
    fi
}

# Function: round float number to specified decimal places
round_number() {
    printf "%.${2}f" "$1"
}

# Define download URLs array
urls="
https://store.storevideos.cdn-apple.com/v1/store.apple.com/st/1666383693478/atvloop-video-202210/streams_atvloop-video-202210/1920x1080/fileSequence3.m4s
https://tbexpand.alicdn.com/aa4055d3f9094c2b/1632968880596/768716378c63550b.mp4_329682839911_mp4_264_hd.mp4
https://speed.cloudflare.com/__down?bytes=104857600
https://cdn.akamai.steamstatic.com/steam/apps/1063730/extras/NW_Sword_Sorcery_2.gif
https://dldir1.qq.com/qqfile/qq/QQNT/Windows/QQ_9.9.15_241009_x64_01.exe
https://epicgames-download1.akamaized.net/Builds/UnrealEngineLauncher/Installers/Mac/EpicInstaller-15.17.1.dmg
https://hyp-webstatic.mihoyo.com/hyp-client/hyp_cn_setup_1.2.2.exe
https://packages.vmware.com/tools/releases/latest/windows/VMware-tools-windows-arm-12.5.0-24276846.iso
https://packages.vmware.com/tools/releases/12.5.0/windows/VMware-tools-windows-12.5.0-24276846.iso
https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso
https://repo1.maven.org/maven2/org/springframework/spring-webmvc/5.2.20.RELEASE/spring-webmvc-5.2.20.RELEASE-javadoc.jar
https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso
https://www.releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso.zsync
https://xyq.gdl.netease.com/XYQDownloader.exe
https://downloader.battlenet.com.cn/download/getInstaller?os=mac&installer=Battle.net-Setup-CN.zip
https://down.val.qq.com/dependencies/dxwebsetup.exe
https://epicgames-download1.akamaized.net/Builds/UnrealEngineLauncher/Installers/Mac/EpicInstaller-15.17.1.dmg
https://dl1.wsyhn.com//fwqk123/3DM-YOUXIYUNXINGKU.v3.0.7z
"

# Initialize total data
total_size=0
total_time=0

# Record start time
start_time=$(date '+%Y-%m-%d %H:%M:%S')

# Loop through URLs for download testing
echo "$urls" | while read -r url; do
    # Skip empty lines
    [ -z "$url" ] && continue

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Testing URL: $url" | tee -a "$DETAIL_LOG"

    # Use curl for download with improved parameters and error handling
    result=$(curl -L -s -w "\nSize: %{size_download} bytes\nSpeed: %{speed_download} bytes/sec\nTime: %{time_total} sec\nHTTP: %{http_code}\n" \
             -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
             --connect-timeout 15 \
             --max-time 60 \
             -o /dev/null \
             "$url" 2>&1)

    # Get curl exit code
    curl_exit=$?

    # Check if curl failed and provide more detailed error information
    if [ $curl_exit -ne 0 ]; then
        error_msg=""
        case $curl_exit in
            6)  error_msg="Could not resolve host";;
            7)  error_msg="Failed to connect";;
            28) error_msg="Operation timeout";;
            *)  error_msg="Curl error code: $curl_exit";;
        esac
        echo "[$timestamp] Failed to download: $url (Error: $error_msg)" | tee -a "$DETAIL_LOG"
        continue
    fi

    # Extract HTTP status code
    http_code=$(echo "$result" | grep "HTTP:" | awk '{print $2}')
    if [ "$http_code" != "200" ]; then
        echo "[$timestamp] HTTP error $http_code for URL: $url" | tee -a "$DETAIL_LOG"
        continue
    fi

    # Extract and convert data with error checking
    size_bytes=$(echo "$result" | grep -o "Size: [0-9]*" | awk '{print $2}')
    speed_bytes=$(echo "$result" | grep -o "Speed: [0-9]*" | awk '{print $2}')
    time_sec=$(echo "$result" | grep -o "Time: [0-9.]*" | awk '{print $2}')

    # Check if we got valid data
    if [ -z "$size_bytes" ] || [ "$size_bytes" -eq 0 ]; then
        echo "[$timestamp] No data received from: $url" | tee -a "$DETAIL_LOG"
        continue
    fi

    # Convert units
    size_mb=$(bytes_to_mb $size_bytes)
    speed_mb=$(bytes_to_mb_per_sec $speed_bytes)
    time_rounded=$(round_number $time_sec 2)

    # Format output to one line
    echo "[$timestamp] Size: ${size_mb} M, Speed: ${speed_mb}MB/sec, Time: ${time_rounded} sec, URL: $url" | tee -a "$DETAIL_LOG"

    # Accumulate total data
    total_size=$((total_size + size_bytes))
    total_time=$(echo $total_time $time_sec | awk '{print $1 + $2}')
done

# Convert total size to GB and average speed to MB/s
total_size_gb=$(bytes_to_gb $total_size)
avg_speed_mb=$(echo $total_size $total_time | awk '{if ($2 > 0) printf "%.2f", ($1 / $2) / (1024 * 1024); else print "0.00"}')

# Record end time and write summary log
end_time=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$end_time] Start Time: $start_time, End Time: $end_time, Total Time: ${total_time}sec, Total Size: ${total_size_gb}GB, Average Speed: ${avg_speed_mb}MB/sec" | tee -a "$SUMMARY_LOG"

echo "[$end_time] Test completed! Check $DETAIL_LOG for details and $SUMMARY_LOG for summary."
