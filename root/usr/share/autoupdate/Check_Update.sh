#!/bin/sh
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001

PING_TARGETS="114.114.114.114 223.5.5.5 8.8.8.8"
MAX_FAILS=3
# 检测网络状态
for target in $PING_TARGETS; do
    if ping -c 1 -W 3 "$target" > /dev/null 2>&1; then
        echo "网络正常 (成功Ping通: $target)"
    else
	echo "您可能没进行联网,请检查网络" > /tmp/cloud_version
	echo "wuwanglou" > /tmp/Version_Tags
	exit 0
    fi
done

if [[ -f "/etc/openwrt_update" ]]; then
	AutoUpdate
	if [[ $? -ne 0 ]]; then
		echo "AutoUpdate.sh运行出错,文件代码或许有错误" > /tmp/cloud_version
		exit 0
	fi
else
	echo "您只编译了LCUI部分，没编译在线更新固件程序" > /tmp/cloud_version
	exit 0
fi

LOCAL_Version=$(grep LOCAL_Version= /tmp/Version_Tags | cut -c15-100)
CLOUD_Version=$(grep CLOUD_Version= /tmp/Version_Tags | cut -c15-100)
LUCI_Firmware=$(grep LUCI_Firmware= /tmp/Version_Tags | cut -c15-100)
if [[ -n "${LOCAL_Version}" ]] && [[ -n "${CLOUD_Version}" ]] && [[ -n "${LUCI_Firmware}" ]]; then
	if [[ "${LOCAL_Version}" -eq "${CLOUD_Version}" ]]; then
		Checked_Type="已是最新"
		echo "${LUCI_Firmware} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${LOCAL_Version}" -lt "${CLOUD_Version}" ]]; then
		Checked_Type="有可更新固件"
		echo "${LUCI_Firmware} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${LOCAL_Version}" -gt "${CLOUD_Version}" ]]; then
		Checked_Type="云端最高版本固件,低于您现在所使用版本,请到云端查看原因"
		echo "${LUCI_Firmware} [${Checked_Type}]" > /tmp/cloud_version	
	fi
fi

exit 0
