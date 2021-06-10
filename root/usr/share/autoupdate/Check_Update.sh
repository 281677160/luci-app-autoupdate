#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001

rm -f /tmp/cloud_version
if [ ! -f /bin/AutoUpdate.sh ];then
	echo "未检测到 /bin/AutoUpdate.sh" > /tmp/cloud_version
	exit
fi
[ -f /etc/openwrt_info ] && source /etc/openwrt_info || {
	echo -e "\n未检测到 /etc/openwrt_info,无法运行更新程序!"
	exit
}
[[ -z "${DEFAULT_Device}" ]] && DEFAULT_Device="$(jsonfilter -e '@.model.id' < "/etc/board.json" | tr ',' '_')"
[[ -z "${Github}" ]] && exit
[ ! -d /tmp/Downloads ] && mkdir -p /tmp/Downloads
wget -q ${Github_Tags} -O - > /tmp/Downloads/Github_Tags
case ${DEFAULT_Device} in
x86-64)
	if [ -d /sys/firmware/efi ];then
		Firmware_SFX="-UEFI.tar.gz"
		BOOT_Type="-UEFI"
	else
		Firmware_SFX="-Legacy.tar.gz"
		BOOT_Type="-Legacy"
	fi
;;
*)
	Firmware_SFX=".tar.gz"
	BOOT_Type=""
;;
esac
Cloud_Ver="$(cat /tmp/Github_Tags | egrep -o "${Firmware_COMP1}-${Firmware_COMP2}-${DEFAULT_Device}-[0-9]+.*?[0-9]+${Firmware_SFX}" | awk 'END {print}' | egrep -o '[a-zA-Z0-9_-]+.*?[0-9]+')"
Cloud_Version="${Cloud_Ver#*${Firmware_COMP1}-}"
if [[ ! -z "${Cloud_Version}" ]];then
	if [[ "${CURRENT_Version}" -eq "${Cloud_Version}" ]];then
		Checked_Type="已是最新"
		echo "${Cloud_Version}${BOOT_Type} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${CURRENT_Version}" -gt "${Cloud_Version}" ]];then
		Checked_Type="发现更新"
		echo "${Cloud_Version}${BOOT_Type} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${CURRENT_Version}" -lt "${Cloud_Version}" ]];then
		echo "您当前的版本高于云端现有版本" > /tmp/cloud_version		
	fi
else
	echo "网络检测失败，没翻墙或者您的是私有仓库，或者云端固件已删除" > /tmp/cloud_version
fi
exit
