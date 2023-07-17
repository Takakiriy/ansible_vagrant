#!/bin/bash
#// run_playbook.sh for Vagrant

PrivateKey_centos7_51=".vagrant/machines/centos7_51/virtualbox/private_key"
LocalPort_centos7_51="2351"

PlaybookPath=$1
Extension="${PlaybookPath##*.}"
if [ "${Extension}" == "yaml"  -o  "${Extension}" == "yml" ]; then
    if echo  "${PlaybookPath}"  |  grep '/';  then
        WorkingFolder="${PlaybookPath%/*}"
        PlaybookPath="${PlaybookPath##*/}"
    else
        WorkingFolder="."
        PlaybookPath="${PlaybookPath}"
    fi
else
    WorkingFolder="${PlaybookPath}"
    PlaybookPath="playbook.yml"
fi

shift
for  argument  in  "$@" ;do
    arguments="${arguments} '${argument}'"
done

ssh  vagrant@localhost  -t  -p ${LocalPort_centos7_51}  -i ${PrivateKey_centos7_51} \
    "cd /vagrant/${WorkingFolder}  &&  echo '(@centos7_51)'  &&  pwd  && " \
    'ANSIBLE_INVENTORY="/tmp/vagrant-ansible/inventory/vagrant_ansible_local_inventory" ' \
    "ansible-playbook  ${PlaybookPath} --diff -v  ${arguments}"
