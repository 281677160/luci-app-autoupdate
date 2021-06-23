#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001

rm -f /tmp/cloud_version
if [ ! -f /bin/AutoUpdate.sh ];then
	echo "未检测到定时更新插件程序" > /tmp/cloud_version
	exit 1
fi
[ -f /etc/openwrt_info ] && source /etc/openwrt_info || {
	echo "未检测到定时更新插件程序!" > /tmp/cloud_version
	exit 1
}
export Google_Check=$(curl -I -s --connect-timeout 8 google.com -w %{http_code} | tail -n1)
if [ ! "$Google_Check" == 301 ];then
	echo "网络检测失败，Github已筑墙，请翻墙或者您的是私有仓库!" > /tmp/cloud_version
	exit 1
fi
[[ -z ${CURRENT_Version} ]] && echo "本地固件版本获取失败,请检查/etc/openwrt_info文件的值!" > /tmp/cloud_version && exit 1
[[ -z "${Github}" ]]  && echo "Github地址获取失败,请检查/etc/openwrt_info文件的值!" > /tmp/cloud_version && exit 1
[ ! -d ${Download_Path} ] && mkdir -p ${Download_Path}
wget -q --timeout 5 ${Github_Tags} -O ${Download_Path}/Github_Tags
case ${DEFAULT_Device} in
x86-64)
	if [ -d /sys/firmware/efi ];then
		Firmware_SFX="-UEFI.${Firmware_Type}"
		BOOT_Type="-UEFI"
	else
		Firmware_SFX="-Legacy.${Firmware_Type}"
		BOOT_Type="-Legacy"
	fi
;;
*)
	Firmware_SFX=".${Firmware_Type}"
	BOOT_Type=""
;;
esac
export CLOUD_Firmware="$(egrep -o "${Egrep_Firmware}-[0-9]+${Firmware_SFX}" ${Download_Path}/Github_Tags | awk 'END {print}')"
export CLOUD_Version="$(echo ${CLOUD_Firmware} | egrep -o "${REPO_Name}-${DEFAULT_Device}-[0-9]+")"
if [[ ! -z "${CLOUD_Version}" ]];then
	if [[ "${CURRENT_Version}" -eq "${CLOUD_Version}" ]];then
		Checked_Type="已是最新"
		echo "${CLOUD_Version}${BOOT_Type} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${CURRENT_Version}" -gt "${CLOUD_Version}" ]];then
		Checked_Type="发现更新"
		echo "${CLOUD_Version}${BOOT_Type} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${CURRENT_Version}" -lt "${CLOUD_Version}" ]];then
		Checked_Type="当前的版本高于云端现有版本"
		echo "${CLOUD_Version}${BOOT_Type} [${Checked_Type}]" > /tmp/cloud_version	
	fi
else
	echo "没检测到云端固件版本，您可能把云端固件删除了，或云端版本和此固件名称格式不对称，如果名称格式不对称请把云端固件全部删除，然后重新编译固件!" > /tmp/cloud_version
fi
exit 0
