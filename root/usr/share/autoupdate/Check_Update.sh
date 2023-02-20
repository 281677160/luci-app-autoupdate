#!/bin/sh
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001


[[ -f /tmp/baidu.html ]] && rm -rf /tmp/baidu.html
curl --connect-timeout 9 -o /tmp/baidu.html -s -w %{time_namelookup}: http://www.baidu.com > /dev/null 2>&1
if [[ -f /tmp/baidu.html ]] && [[ `grep -c "百度一下" /tmp/baidu.html` -ge '1' ]]; then
	rm -rf /tmp/baidu.html
else
	echo "您可能没进行联网,请检查网络,或您的网络不能连接百度?" > /tmp/cloud_version
	echo "wuwanglou" > /tmp/Version_Tags
	exit 0
fi

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
