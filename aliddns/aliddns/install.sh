#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=$(nvram get productid)
module=aliddns
DIR=$(cd $(dirname $0); pwd)

# 获取固件类型
_get_type() {
	local FWTYPE=$(nvram get extendno|grep koolshare)
	if [ -d "/koolshare" ];then
		if [ -n $FWTYPE ];then
			echo "koolshare官改固件"
		else
			echo "koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			echo "梅林原版固件"
		else
			echo "华硕官方固件"
		fi
	fi
}

exit_install(){
	local state=$1
	case $state in
		1)
			echo_date "本插件适用于适用于【koolshare 官改 qca-ipq806x】固件平台，你的固件平台不能安装！！！"
			echo_date "本插件支持机型/平台：https://github.com/koolshare/qcasoft#qcasoft"
			echo_date "退出安装！"
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 1
			;;
		0|*)
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 0
			;;
	esac
}

# 判断路由架构和平台
case $(uname -m) in
	armv7l)
		if [ "$MODEL" == "RT-AX89U" ] && [ -d "/koolshare" ];then
			echo_date 机型：$MODEL $(_get_type) 符合安装要求，开始安装插件！
		else
			exit_install 1
		fi
		;;
	*)
		exit_install 1
	;;
esac

# stop aliddns first
enable=$(dbus get aliddns_enable)
if [ "$enable" == "1" ]; then
	sh /koolshare/scripts/aliddns_config.sh stop
fi

# delete some files
rm -rf /koolshare/init.d/*aliddns.sh

# install
cp -rf /tmp/aliddns/scripts/* /koolshare/scripts/
cp -rf /tmp/aliddns/webs/* /koolshare/webs/
cp -rf /tmp/aliddns/res/* /koolshare/res/
cp -rf /tmp/aliddns/uninstall.sh /koolshare/scripts/uninstall_aliddns.sh
chmod +x /koolshare/scripts/aliddns*
chmod +x /koolshare/init.d/*
[ ! -L "/koolshare/init.d/S98Aliddns.sh" ] && ln -sf /koolshare/scripts/aliddns_config.sh /koolshare/init.d/S98Aliddns.sh

# 离线安装需要向skipd写入安装信息
dbus set aliddns_version="$(cat $DIR/version)"
dbus set softcenter_module_aliddns_version="$(cat $DIR/version)"
dbus set softcenter_module_aliddns_install="1"
dbus set softcenter_module_aliddns_name="aliddns"
dbus set softcenter_module_aliddns_title="阿里DDNS"
dbus set softcenter_module_aliddns_description="aliddns"

# re-enable aliddns
if [ "$enable" == "1" ];then
	sh /koolshare/scripts/aliddns_config.sh ks 1
fi

# 完成
echo_date 阿里ddns插件安装完毕！
exit_install
