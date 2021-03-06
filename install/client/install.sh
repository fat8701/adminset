#!/bin/bash
#
service adminsetd stop
set -e
cd "$( dirname "$0"  )"
cur_dir=$(pwd)
work_dir=/var/opt/adminset/client
# 安装依赖包
os=$(cat /proc/version)
if (echo $os|grep centos) || (echo $os|grep 'Red Hat')
then
    yum makecache fast
    yum install -y epel-release
    yum install -y gcc smartmontools dmidecode python-pip python-devel dos2unix
elif (echo $os|grep Ubuntu)
then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y gcc smartmontools dmidecode python-pip python-dev tofrodos
#    sed -i "s/PermitRootLogin/\#PermitRootLogin/g" /etc/ssh/sshd_config
#    service ssh restart
else
    echo "your os version is not supported!"
fi


echo "####install pip mirror####"
mkdir -p  ~/.pip
cat <<EOF > ~/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF

echo "####install pip packages####"
mkdir -p $work_dir

	
echo "####config adminset agent####"
if (echo $os|grep centos) || (echo $os|grep 'Red Hat')
then
    if (rpm -ql python|grep 2.6)
    then
        pip install -U pip==9.0.3
        pip install virtualenv==14.0.0
        pip install setuptools==28.5.0
        scp $cur_dir/adminset_agent.py $work_dir
        scp $cur_dir/uninstall.sh $work_dir
        scp $cur_dir/adminsetd /etc/init.d/
        dos2unix $work_dir/adminset_agent.py
        dos2unix /etc/init.d/adminsetd
        chmod +x /etc/init.d/adminsetd
    else
        pip install -U pip==19.0.3
        pip install virtualenv==15.2.0
        scp $cur_dir/adminset_agent.py $work_dir
        scp $cur_dir/uninstall.sh $work_dir
        scp $cur_dir/adminsetd.service /usr/lib/systemd/system/
        dos2unix $work_dir/adminset_agent.py
        dos2unix /usr/lib/systemd/system/adminsetd.service
        systemctl daemon-reload
    fi
    chkconfig adminsetd on
elif (echo $os|grep Ubuntu)
then
    pip install -U pip==19.0.3
	cp /usr/local/bin/pip /usr/bin/pip   ##解决ubuntu下升级pip后报错问题
    pip install virtualenv==15.2.0
    scp $cur_dir/adminset_agent.py $work_dir
    scp $cur_dir/uninstall.sh $work_dir
    scp $cur_dir/adminsetd.service /lib/systemd/system/
    fromdos $work_dir/adminset_agent.py
    fromdos /lib/systemd/system/adminsetd.service
    systemctl daemon-reload
    systemctl enable adminsetd
else
    echo "your os version is not supported!"
fi

cd $work_dir
virtualenv venv
source $work_dir/venv/bin/activate
#pip install python-daemon==2.1.2
pip install requests==2.11.1
pip install psutil==5.2.2
pip install schedule==0.4.3

echo "####client prepare finished!###"
#ubuntu_version=`cat /proc/version|grep 16.04`
#if [ "$ubuntu_version" ]
#then
#    systemctl daemon-reload
#fi
service adminsetd start
echo "####client install finished!###"
echo "please using <service or systemd adminsetd start|restart|stop> manage adminset agent"
