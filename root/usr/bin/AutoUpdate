#!/bin/sh
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoUpdate for Openwrt

Input_Option=$1
Version=V7.2
function information_acquisition() {
source /etc/openwrt_update
Kernel=$(egrep -o "[0-9]+\.[0-9]+\.[0-9]+" /usr/lib/opkg/info/kernel.control)
[ ! -d "${Download_Path}" ] && mkdir -p ${Download_Path} || rm -rf "${Download_Path}"/*
opkg list | awk '{print $1}' > ${Download_Path}/Installed_PKG_List
PKG_List="${Download_Path}/Installed_PKG_List"


wget -qT 10 --no-check-certificate ${Github_API1} -O ${API_PATH}
if [[ -f "${API_PATH}" ]] && [[ `grep -c "url" ${API_PATH}` -ge '1' ]]; then
  CHN_NET="1"
else
  CHN_NET="0"
fi

if [[ "${CHN_NET}" == "0" ]]; then
  curl --connect-timeout 10 "baidu.com" > "/dev/null" 2>&1 || wangluo='1'
fi
if [[ "${wangluo}" == "1" ]]; then
  curl --connect-timeout 10 "google.com" > "/dev/null" 2>&1 || wangluo='2'
fi
if [[ "${wangluo}" == "1" ]] && [[ "${wangluo}" == "2" ]]; then
  echo "您可能没进行联网,请检查网络?" > /tmp/cloud_version
  exit 1
fi

if [[ "${CHN_NET}" == "0" ]]; then
  wget -q --no-check-certificate ${Github_API2} -O ${API_PATH}
fi
if [[ $? -ne 0 ]];then
  curl -fsSL -o ${API_PATH} ${Github_API2}
fi
if [[ -f "${API_PATH}" ]] && [[ `grep -c "url" ${API_PATH}` -ge '1' ]]; then
  echo "获取API数据成功!" > /tmp/cloud_version
else
  echo "获取API数据失败,Github地址不正确，或此地址没云端存在，或您的仓库为私库!" > /tmp/cloud_version
  exit 1
fi

case "${TARGET_BOARD}" in
x86)
  [ -d '/sys/firmware/efi' ] && {
    BOOT_Type=uefi
  } || {
    BOOT_Type=legacy
  }
  CURRENT_Device=$(cat /proc/cpuinfo |grep 'model name' |awk 'END {print}' |cut -f2 -d: |sed 's/^[ ]*//g'|sed 's/\ CPU//g')
  [[ -z "${CURRENT_Device}" ]] && CURRENT_Device="${DEFAULT_Device}"
;;
*)
  CURRENT_Device=$(jsonfilter -e '@.model.id' < /etc/board.json | tr ',' '_')
  BOOT_Type=sysupgrade
esac

LOCAL_Version=$(echo "${CURRENT_Version}"|egrep -o [0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+)
CLOUD_Firmware=$(egrep -o "${CLOUD_CHAZHAO}-[0-9]+-${BOOT_Type}-[a-zA-Z0-9]+${Firmware_SFX}" ${API_PATH} | awk 'END {print}')
CLOUD_Version=$(echo "${CLOUD_Firmware}"|egrep -o [0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+[0-9]+)
LUCI_Firmware=$(echo ${CLOUD_Firmware} | egrep -o "${SOURCE}-${DEFAULT_Device}-[0-9]+")
if [[ -z "${CLOUD_Firmware}" ]]; then
  echo "获取云端固件版本信息失败,如果是x86的话,注意固件的引导模式是否对应,或者是蛋痛的脚本作者修改过脚本导致固件版本信息不一致!" > /tmp/cloud_version
  exit 1
fi

cat > /tmp/Version_Tags <<-EOF
LOCAL_Version=${LOCAL_Version}
CLOUD_Version=${CLOUD_Version}
LUCI_Firmware=${LUCI_Firmware}
MODEL_type=${BOOT_Type}${Firmware_SFX}
KERNEL_type=${Kernel} - ${LUCI_EDITION}
CURRENT_Device=${CURRENT_Device}
EOF
echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 信息检测完毕]" > /tmp/cloud_version
}

function firmware_upgrade() {
TMP_Available=$(df -m | grep "/tmp" | awk '{print $4}' | awk 'NR==1' | awk -F. '{print $1}')
let X=$(grep -n "${CLOUD_Firmware}" ${API_PATH} | tail -1 | cut -d : -f 1)-4
let CLOUD_Firmware_Size=$(sed -n "${X}p" ${API_PATH} | egrep -o "[0-9]+" | awk '{print ($1)/1048576}' | awk -F. '{print $1}')+1
if [[ "${TMP_Available}" -lt "${CLOUD_Firmware_Size}" ]]; then
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 固件tmp空间值[${TMP_Available}M],云端固件体积[${CLOUD_Firmware_Size}M],空间不足，不能下载]" >> /tmp/AutoUpdate.log
  exit 1
else
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 固件tmp空间值[${TMP_Available}M],云端固件体积[${CLOUD_Firmware_Size}M]]" > /tmp/AutoUpdate.log
fi

if [[ "${LOCAL_Version}" -lt "${CLOUD_Version}" ]]; then
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 检测到有可更新的固件版本,立即更新固件!]" >> /tmp/AutoUpdate.log
else
  echo "${LOCAL_Version} = ${CLOUD_Version}"
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 已是最新版本，无需更新固件!]" >> /tmp/AutoUpdate.log
  exit 0
fi

cd "${Download_Path}"
curl --connect-timeout 10 "https://github.com" > "/dev/null" 2>&1 || gitcom='1'
if [ "${gitcom}" == "1" ]; then
  DOWNLOAD=https://ghproxy.com/${Release_download}
else
  DOWNLOAD=${Release_download}
fi
echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 正在下载云端固件,请耐心等待..]" >> /tmp/AutoUpdate.log
curl -fsSL -o ${CLOUD_Firmware} ${DOWNLOAD}/${CLOUD_Firmware}
if [[ $? -ne 0 ]];then
  wget -q "${DOWNLOAD}/${CLOUD_Firmware}" -O ${CLOUD_Firmware}
fi
if [[ $? -ne 0 ]];then
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 下载云端固件失败,请检查网络再尝试或手动安装固件]" >> /tmp/AutoUpdate.log
  exit 1
else
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 下载云端固件成功!]" >> /tmp/AutoUpdate.log
fi

cd "${Download_Path}"
Google_Check=$(curl -I -s --connect-timeout 8 google.com -w %{http_code} | tail -n1)
if [ ! "${Google_Check}" == 301 ]; then
  DOWNLOAD=https://ghproxy.com/${Release_download}
else
  DOWNLOAD=${Release_download}
fi
wget -q --no-check-certificate ${DOWNLOAD}/${CLOUD_Firmware} -O ${CLOUD_Firmware}
if [[ $? -ne 0 ]];then
  curl -fsSL -o ${CLOUD_Firmware} ${DOWNLOAD}/${CLOUD_Firmware}
fi
if [[ $? -ne 0 ]];then
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 下载云端固件失败,请检查网络再尝试或手动安装固件]" >> /tmp/AutoUpdate.log
  exit 1
else
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 下载云端固件成功!]" >> /tmp/AutoUpdate.log
fi

export LOCAL_MD5=$(md5sum ${CLOUD_Firmware} | cut -c1-3)
export LOCAL_256=$(sha256sum ${CLOUD_Firmware} | cut -c1-3)
export MD5_256=$(echo ${CLOUD_Firmware} | egrep -o "[a-zA-Z0-9]+${Firmware_SFX}" | sed -r "s/(.*)${Firmware_SFX}/\1/")
export CLOUD_MD5="$(echo "${MD5_256}" | cut -c1-3)"
export CLOUD_256="$(echo "${MD5_256}" | cut -c 4-)"
if [[ ! "${LOCAL_MD5}" == "${CLOUD_MD5}" ]]; then
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") MD5对比失败,固件可能在下载时损坏,请检查网络后重试!]" >> /tmp/AutoUpdate.log
  exit 1
fi
if [[ ! "${LOCAL_256}" == "${CLOUD_256}" ]]; then
  echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") SHA256对比失败,固件可能在下载时损坏,请检查网络后重试!]" >> /tmp/AutoUpdate.log
  exit 1
fi

cd "${Download_Path}"
echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 正在执行更新,更新期间请不要断开电源或重启设备 ...]" >> /tmp/AutoUpdate.log
chmod 777 "${CLOUD_Firmware}"
[[ "$(cat ${PKG_List})" =~ "gzip" ]] && opkg remove gzip > /dev/null 2>&1
sleep 2
if [[ -f "/etc/deletefile" ]]; then
  chmod 775 "/etc/deletefile"
  source /etc/deletefile
fi
rm -rf /etc/config/luci
echo "*/5 * * * * sh /etc/networkdetection > /dev/null 2>&1" >> /etc/crontabs/root
rm -rf /mnt/*upback.tar.gz && sysupgrade -b /mnt/upback.tar.gz
if [[ `ls -1 /mnt | grep -c "upback.tar.gz"` -eq '1' ]]; then
  Upgrade_Options='sysupgrade -f /mnt/upback.tar.gz'
else
  Upgrade_Options='sysupgrade -q'
fi
echo "[$(date "+%Y年%m月%d日%H时%M分%S秒") 升级固件中，请勿断开路由器电源，END]" >> /tmp/AutoUpdate.log
${Upgrade_Options} ${CLOUD_Firmware}
}


if [[ -z "${Input_Option}" ]]; then
  information_acquisition
else
  case ${Input_Option} in
  -u)
  information_acquisition
  firmware_upgrade
  ;;
  esac
fi
