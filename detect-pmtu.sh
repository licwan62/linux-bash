#!/bin/bash

# 自动二分查找最大可连通的 ping 包大小
# 算出对应 PMTU 和 建议 TCP MSS

# 用法: ./detect-pmtu.sh <目标IP>   例: ./detect-pmtu.sh 10.1.0.217

target="$1"
if [ -z "$target" ]; then
  echo "Usage: $0 <target_ip>"
  exit 1
fi

echo "==> Testing PMTU to $target ..."
min=500
max=1472   # 1500-28
best=0

# 二分查找可达最大包
while [ $min -le $max ]; do
  mid=$(( (min + max) / 2 ))
  ping -c1 -W1 -M do -s "$mid" "$target" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    best=$mid
    min=$(( mid + 1 ))
  else
    max=$(( mid - 1 ))
  fi
done

if [ $best -gt 0 ]; then
  pmtu=$(( best + 28 ))
  mss=$(( pmtu - 40 ))
  echo "✅ 最大可连通负载: $best bytes"
  echo "✅ 路径 PMTU:       $pmtu bytes"
  echo "✅ 建议 TCP MSS:    $mss bytes"
  echo
  echo "👉 临时生效修复命令:"
  echo "   iptables -t mangle -A OUTPUT -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss $mss"
else
  echo "❌ 测试失败，可能目标无 ICMP 响应。"
fi
