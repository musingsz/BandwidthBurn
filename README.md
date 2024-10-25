# BandwidthBurn
“Bandwidth Burn” 是一个测试网络下载能力，期间会大量消耗下行网络带宽序，可通过 Docke部署。

# 自带监控页面
访问 http://ip:8182 可访问监控页面，可以查看 12个月的流量使用情况。以及每天的下载数据统计。

# Docker 镜像打包
docker build -t musings/bandwidthburn:0.5 .

# Docker 运行
docker run -d --name bandwidthburn musings/bandwidthburn  -p 8212:8212  
