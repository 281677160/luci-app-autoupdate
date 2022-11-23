#!/bin/sh
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001

if [[ -f "/usr/bin/AutoUpdate" ]] && [[ -f "/etc/openwrt_update" ]]; then
	AutoUpdate
	if [[ $? -ne 0 ]]; then
		exit 1
	fi
else
	echo "您只编译了LCUI部分，没编译在线更新固件程序" > /tmp/cloud_version
	exit 1
fi

source /tmp/Version_Tags

if [[ -n "${CLOUD_Version}" ]]; then
	if [[ "${LOCAL_Version}" == "${CLOUD_Version}" ]]; then
		Checked_Type="已是最新"
		echo "${LUCI_Firmware} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${LOCAL_Version}" -lt "${CLOUD_Version}" ]]; then
		Checked_Type="发现更高版本固件可更新"
		echo "${LUCI_Firmware} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${LOCAL_Version}" -gt "${CLOUD_Version}" ]]; then
		Checked_Type="云端最高版本固件,低于您现在所安装的版本,请到云端查看原因"
		echo "${LUCI_Firmware} [${Checked_Type}]" > /tmp/cloud_version	
	fi
else
	echo "未知原因获取不了云端固件的版本信息" > /tmp/cloud_version
	exit 1
fi

exit 0
