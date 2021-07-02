#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001

export Google_Check=$(curl -I -s --connect-timeout 8 google.com -w %{http_code} | tail -n1)
if [ ! "$Google_Check" == 301 ];then
	echo "网络检测失败,因Github现在也筑墙了,请先使用梯子翻墙再来尝试!" > /tmp/cloud_version
	sleep 2
	exit 1
fi
rm -f /tmp/cloud_version
rm -f /tmp/Version_Tags
if [ ! -f /bin/AutoUpdate.sh ];then
	echo "未检测到定时更新插件程序" > /tmp/cloud_version
	exit 1
else
	bash /bin/AutoUpdate.sh	-w
fi
source /tmp/Version_Tags
if [[ ! -z "${CLOUD_Version}" ]];then
	if [[ "${CURRENT_Version}" -eq "${CLOUD_Version}" ]];then
		Checked_Type="已是最新"
		echo "${CLOUD_Version} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${CURRENT_Version}" -gt "${CLOUD_Version}" ]];then
		Checked_Type="发现更新"
		echo "${CLOUD_Version} [${Checked_Type}]" > /tmp/cloud_version
	elif [[ "${CURRENT_Version}" -lt "${CLOUD_Version}" ]];then
		Checked_Type="当前的版本高于云端现有版本"
		echo "${CLOUD_Version} [${Checked_Type}]" > /tmp/cloud_version	
	fi
else
	echo "没检测到云端固件，您可能把云端固件删除了，或格式不对称，比如爱快虚拟机安装固件不管什么格式都会变成Legacy引导!" > /tmp/cloud_version
fi
exit 0
