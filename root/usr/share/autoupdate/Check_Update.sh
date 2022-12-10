#!/bin/sh
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001

[[ -f "/tmp/Version_Tags" ]] && rm -rf /tmp/Version_Tags

if [[ -f "/usr/bin/AutoUpdate" ]] && [[ -f "/bin/openwrt_info" ]]; then
	AutoUpdate -w
	if [[ $? -ne 0 ]]; then
		exit 1
	fi
else
	echo "您只编译了LCUI部分，没编译在线更新固件程序" > /tmp/cloud_version
	exit 1
fi

if [[ -f "/tmp/Version_Tags" ]]; then
	LOCAL_Firmware="$(grep 'LOCAL_Firmware=' "/tmp/Version_Tags" | cut -d "-" -f4)"
	CLOUD_Firmware="$(grep 'CLOUD_Firmware=' "/tmp/Version_Tags" | cut -d "-" -f4)"
	CLOUD_Firmware2="$(grep 'CLOUD_Firmware=' "/tmp/Version_Tags" | cut -d "=" -f2)"
else
	echo "未知原因获取不了版本信息" > /tmp/cloud_version
	exit 1
fi

if [[ -n "${CLOUD_Firmware}" ]]; then
	if [[ "${LOCAL_Firmware}" -eq "${CLOUD_Firmware}" ]]; then
		Checked_Type="已是最新"
		echo "${CLOUD_Firmware2} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${LOCAL_Firmware}" -lt "${CLOUD_Firmware}" ]]; then
		Checked_Type="发现更高版本固件可更新"
		echo "${CLOUD_Firmware2} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${LOCAL_Firmware}" -gt "${CLOUD_Firmware}" ]]; then
		Checked_Type="云端最高版本固件,低于您现在所安装的版本,请到云端查看原因"
		echo "${CLOUD_Firmware2} [${Checked_Type}]" > /tmp/cloud_version	
	fi
else
	echo "未知原因获取不了云端固件的版本信息" > /tmp/cloud_version
	exit 1
fi

exit 0
