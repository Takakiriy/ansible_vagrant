#!/bin/bash
#// run_playbook.sh for WSL2

SharedFolder=/mnt/c/Users/${USERNAME}/vagrant/single_vm_ansible/centos7
HostName=ubuntu20_04_Ansible
UserName=user1
PrivateKey_ubuntu20_76=".wsl/${HostName}/id_rsa"

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

ssh  ${UserName}@${HostName}  -t \
    "cd ${SharedFolder}/${WorkingFolder}  &&  echo '(@ubuntu20_76)'  &&  pwd  && " \
    "ansible-playbook  ${PlaybookPath} --diff -v  ${arguments}"
