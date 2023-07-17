#!/bin/bash

ParentFolderName="$( readlink -f "$0"  |  sed 's/\(.*\)\/.*/\1/'  |  sed 's/.*\///' )"
ProjectName="${ParentFolderName}"
VirtualBoxVMName="centos7_51"
SSHHostName="${ProjectName}_${VirtualBoxVMName}"
LocalPortNumber=2351
if [ "${USERPROFILE}" == "" ]; then  #// for WSL2
    export USERNAME="$( cmd.exe /c 'echo %USERNAME%' )"
    export USERNAME="${USERNAME:0:${#USERNAME}-1}"  #// Cut last CR
    export USERPROFILE="/mnt/c/Users/${USERNAME}"
fi
if [ "${HOME:0:3}" == "/c/" ]; then  #// for Git bash
    export USERPROFILE="${HOME}"
fi
SSHConfigPath="${USERPROFILE}/.ssh/config"
SSHKnownHostsPath="${USERPROFILE}/.ssh/known_hosts"
VMBackUpPath="${USERPROFILE}/Desktop/VM_back_up"
VirtualBoxVMPath="${USERPROFILE}/VirtualBox VMs"

function  Main() {
    local  command="$1"
    if [ "${command}" == "" ]; then
        echo  "Create a VM ..."
        if false; then
            echo  ""  #// dummy command for if statement
        else  #// Move this line
            # SetUpVagrantForWSL2
            CheckIfOldVMWasRemoved
            RunInGitBash  vagrant.exe  plugin install vagrant-vbguest  ||  Error
            RunInGitBash  vagrant.exe  plugin install vagrant-proxyconf  ||  Error

            RunInGitBash  vagrant.exe  up  ||  Error
            SetVagrantSshConfig  "${SSHHostName}"  ||  Error
            RemoveOldKnownHost  "${LocalPortNumber}"  ||  Error

            ShutdownVM  ||  Error
            BackUpVM  "VM0"  ||  Error
            RunInGitBash  vagrant.exe  up  ||  Error

            RunInGitBash  ./run_playbook.sh  "playbook.yml"  ||  Error
        fi
    elif [ "${command}" == "shutdown" ]; then
        ShutdownVM
    elif [ "${command}" == "backup" ]; then
        local  backUpTo="$2"
        BackUpVM  "${backUpTo}"
    elif [ "${command}" == "restore" ]; then
        local  restoreFrom="$2"
        RestoreVM  "${restoreFrom}"
    elif [ "${command}" == "port" ]; then
        SetVagrantSshConfig  "${SSHHostName}"  ||  Error
    else
        echo  "Unknown command ${command}" >&2
        exit 2
    fi
}

function  CheckIfOldVMWasRemoved() {
    if [ -e "${VirtualBoxVMPath}" ]; then
        local  shutdownedVMName="$( ExpandFolderNameWildcard  "${VirtualBoxVMPath}/${ProjectName}_*"  |  sed -n 1P )"
        local  shutdownedVMPath="${VirtualBoxVMPath}/${shutdownedVMName}"

        if [ "${shutdownedVMName}" != "" ]; then
            Error  "ERROR: Old VM exists in \"${shutdownedVMPath}\""
            exit  2
        fi
        if [ -e ".vagrant" ]; then
            Error  "ERROR: Old .vagrant folder exists in \"$( readlink -f .vagrant )\""
            exit  2
        fi
    fi
}

function  SetUpVagrantForWSL2() {
    local  vagrantInstalled="${False}"
    if [ ! -e "/mnt/c/Users" ]; then
        return  #// Not in WSL2
    fi

    export  VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
    export  VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="${USERPROFILE}"
    export  PATH="$PATH:/mnt/c/Programs/Virtualbox"
    if [ ! -e "/mnt/c/Programs/Virtualbox" ]; then
        Error  "ERROR: Not installed VirtualBox for Windows"
    fi
    vagrant -v  &&  vagrantInstalled="${True}"
    if [ "${vagrantInstalled}" == "${False}" ]; then

        echo  "Installing Vagrant..."
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
        sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
        sudo apt-get update
        sudo apt-get install vagrant
        vagrant -v  &&  vagrantInstalled="${True}"
        if [ "${vagrantInstalled}" == "${False}" ]; then
            Error  "ERROR: Failed to install Vagrant"
        fi
    fi
}

function  SetVagrantSshConfig() {
    local  hostNameInHostOS="$1"
    local  hostNameInVagrant="$2"  #// ""= Use first config

    echo  "SetVagrantSshConfig \"${SSHConfigPath}\""
    local  configPath="${SSHConfigPath}"
    if [ ! -e "${configPath}" ]; then
        mkdir -p  "${configPath%/*}"
        touch  "${configPath}"
    fi
    local  configBackupPath="${configPath}.bak"
    local  configInHostOS="$( cat "${configPath}" )"
    local  hostNamesInHostOS="$( echo "${configInHostOS}"  |  grep -n "^Host "  |  sed -n "/Host ${hostNameInHostOS}/,/Host/p" )"
    local  hostHeader="$(     echo  "${hostNamesInHostOS}"  |  sed -n 1P )"
    local  nextHostHeader="$( echo  "${hostNamesInHostOS}"  |  sed -n 2P )"
    local  startLineNum=${hostHeader%%:*}
    local  nextLineNum=${nextHostHeader%%:*}

    local  configInVagrant="$( $RunVagrantSshConfig )"
    if [ "${configInVagrant}" == "" ]; then
        echo  "SetVagrantSshConfig: skipped settings, because of no connection to the VM."
        return
    fi
    local  newConfig="$( echo "${configInVagrant}"  |  sed -n "/^Host ${hostNameInVagrant}/,/^Host/p"  |  sed  '1d;$d' )"
    local  newConfig=\
"Host ${hostNameInHostOS}
${newConfig}"

    if [ ! -e "${configBackupPath}" ]; then
        cp -ap  "${configPath}"  "${configBackupPath}"
    fi

    local  configInHostOS="$( UpdateInText  "${configInHostOS}"  "${startLineNum}"  "${nextLineNum}"  "${newConfig}" )"
    echo  "${configInHostOS}"  >  "${configPath}"
    echo  ""                  >>  "${configPath}"
}

function  UpdateInText() {
    local  oldText="$1"       #// This format is like a "~/.ssh/config" file
    local  startLineNum="$2"  #// ""= Add to last
    local  nextLineNum="$3"   #// ""= Update last part
    local  newPartText="$4"

    if [ "${startLineNum}" == "" ]; then
        echo \
"${oldText}

${newPartText}
"
    else
        if [ "${startLineNum}" == "1" ]; then
            if [ "${nextLineNum}" == "" ]; then
                echo \
"${newPartText}
"
            else
                local  bottomText="$( echo  "${oldText}"  |  sed -n "${nextLineNum}"',$p' )"
                echo \
"${newPartText}

${bottomText}
"
            fi
        else
            local  topText="$( echo  "${oldText}"  |  sed  "${startLineNum}"',$d' )"
            if [ "${nextLineNum}" == "" ]; then
                echo \
"${topText}

${newPartText}
"
            else
                local  bottomText="$( echo  "${oldText}"  |  sed -n "${nextLineNum}"',$p' )"
                echo \
"${topText}

${newPartText}

${bottomText}"
            fi
        fi
    fi
}

function  RunVagrantSshConfig() {
    vagrant.exe ssh-config
}
RunVagrantSshConfig="RunVagrantSshConfig"

function  RunVagrantSshConfig_Mock() {
    echo  "${VagrantSshConfigMock}"
}

function  RunVagrantSshConfig_AttachMock() {
    local  type="$1"
    if [ "${type}" == "original" ]; then
        RunVagrantSshConfig="RunVagrantSshConfig"
    else
        RunVagrantSshConfig="RunVagrantSshConfig_Mock"
        local  space2="  "
        if [ "${type}" == "OneVM" ]; then
            VagrantSshConfigMock=\
"Host centos7
${space2}HostName 127.0.0.1
${space2}User vagrant
${space2}Port 2352
${space2}UserKnownHostsFile /dev/null
${space2}StrictHostKeyChecking no
${space2}PasswordAuthentication no
${space2}IdentityFile C:/Users/${USERNAME}/vagrant/single_vm_ansible/GoCD/.vagrant/machines/centos7/virtualbox/private_key
${space2}IdentitiesOnly yes
${space2}LogLevel FATAL

"
        else
            VagrantSshConfigMock="not defined"
        fi
    fi
}

function  RemoveOldKnownHost() {
    local  localPortNumber="$1" 

    echo  "RemoveOldKnownHost in \"${SSHKnownHostsPath}\""
    local  configPath="${SSHKnownHostsPath}"
    local  configBackupPath="${configPath}.bak"
    local  regularExpression='^\[localhost\]:'"${localPortNumber} "
    if [ -e "${configPath}" ]; then
        local  knownHosts="$( cat "${configPath}" )"

        if [ ! -e "${configBackupPath}" ]; then
            cp -ap  "${configPath}"  "${configBackupPath}"
        fi

        DeleteMatchedLines  "${knownHosts}"  "${regularExpression}"  >  "${configPath}"
    fi
}

function  DeleteMatchedLines() {
    local  oldText="$1"
    local  regularExpression="$2"

    local  deletingLineNums="$( echo  "${oldText}"  |  grep -n  "${regularExpression}"  |  sed "s/:.*//"  |  xargs  echo  |  sed 's/ /d;/' )"
    if [ "${deletingLineNums}" == "" ]; then
        echo  "${oldText}"
    else
        echo  "${oldText}"  |  sed  "${deletingLineNums}d;" 
    fi
}

function  ShutdownVM() {
    local  after="$1"
    echo  "ShutdownVM"
    if [ "${after}" == "" ]; then  after="60s"  ;fi
    sleep "${after}"
    RunInGitBash  ssh  vagrant@localhost  -p ${LocalPortNumber}  -i .vagrant/machines/${VirtualBoxVMName}/virtualbox/private_key \
        -o 'StrictHostKeyChecking no' \
        'sudo shutdown -h now'
    echo  "Done."
}

# RunInGitBash
# Example:
#    - RunInGitBash  pwd
#    - RunInGitBash  ls  '/c/Program Files (x86)'
function  RunInGitBash() {
    if [ "${USERPROFILE:0:5}" == "/mnt/" ]; then  #// WSL2
        local  commandLine=""
        until [ "$1" == "" ]; do
            commandLine="${commandLine} \"$1\""
            shift
        done

        "/mnt/c/Program Files/Git/bin/bash.exe" -c  "$commandLine"
    else  #// Git bash
        "$@"
    fi
}

function  BackUpVM() {
    local  backUpName="$1"
    local  backUpPath="${VMBackUpPath}/${SSHHostName}/${backUpName}"
    local  shutdownedVMName="$( ExpandFolderNameWildcard  "${VirtualBoxVMPath}/${ProjectName}_*"  |  sed -n 1P )"
    local  shutdownedVMPath="${VirtualBoxVMPath}/${shutdownedVMName}"
    if [ "${backUpName}" == "" ]; then
        Error  "backUpName was not specfied."
    fi

    echo  "BackUpVM \"${backUpName}\""
    SafeFolderDelete  "${backUpPath}"  ".vagrant"
    mkdir -p  "${backUpPath}/${shutdownedVMName}"

    CopyFolder  ".vagrant/"  "${backUpPath}/.vagrant/"
    CopyFolder  "${shutdownedVMPath}/"  "${backUpPath}/${shutdownedVMName}/"
}

function  RestoreVM() {
    local  backUpName="$1"
    local  backUpPath="${VMBackUpPath}/${SSHHostName}/${backUpName}"
    local  shutdownedVMName="$( ExpandFolderNameWildcard  "${backUpPath}/${ProjectName}_*"  |  sed -n 1P )"
    local  shutdownedVMPath="${VirtualBoxVMPath}/${shutdownedVMName}"
    if [ "${backUpName}" == "" ]; then
        Error  "backUpName was not specfied."
    fi

    echo  "RestoreVM \"${backUpName}\""
    SafeFolderDelete  "${shutdownedVMPath}"  "*.vmdk"
    rm -rf  ".vagrant/"

    CopyFolder  "${backUpPath}/.vagrant/"  ".vagrant/"
    CopyFolder  "${backUpPath}/${shutdownedVMName}/"  "${shutdownedVMPath}/"
}

function  CopyFolder() {
    local  source="$1"
    local  destination="$2"
    local  ignoreDotGit="$3"  #// ${True}, ${False}(default)
    local  excludeOption="--exclude=./.git"
    source="$( CutLastOf  "${source}"  "/" )"
    destination="$( CutLastOf  "${destination}"  "/" )"
    if [ "${ignoreDotGit}" != ""  -a  "${ignoreDotGit}" != "${excludeOption}" ]; then
        TestError  "Bad option: ${ignoreDotGit}"
        return  "${False}"
    fi

    mkdir -p  "${destination}/"
    if [ "${ignoreDotGit}" == "${excludeOption}" ]; then
        ls -a "${source}" | grep -v  -e "^\.git$"  -e "^\.$"  -e "^\.\.$" | xargs  -I {} \
            cp -Rap  "${source}/{}"  "${destination}/"
    else
        ls -a "${source}" | grep -v  -e "^\.$"  -e "^\.\.$" | xargs  -I {} \
            cp -Rap  "${source}/{}"  "${destination}/"
    fi
}

function  SafeFolderDelete() {
    local  deletingFolderPath="$1"
    local  expectedRelativePathPattern="$2"  #// e.g.) "*.vmdk"
    deletingFolderPath="$( CutLastOf "${deletingFolderPath}" )"

    if [ ! -e "${deletingFolderPath}" ]; then
        return
    fi

    AssertExist  "${deletingFolderPath}/${expectedRelativePathPattern}"

    rm -rf  "${deletingFolderPath}"
}

function  CutLastOf() {
    local  wholeString="$1"
    local  lastExpected="$2"

    if [ "${wholeString:${#wholeString}-${#lastExpected}:${#lastExpected}}" == "${lastExpected}" ]; then
        echo  "${wholeString:0:${#wholeString}-${#lastExpected}}"
    else
        echo  "${wholeString}"
    fi
}

function  ExpandFolderNameWildcard() {
    local  pathWithWildcard="$1"  #// e.g.) /path/to/folder_*
    local  leftOfWildcard="${pathWithWildcard%\**}"
    local  rightOfWildcard="${pathWithWildcard##*\**}"
    local  noWildcard="${True}"
    if [ "${leftOfWildcard}" != "${pathWithWildcard}" ]; then  noWildcard="${False}"  ;fi

    if [ "${noWildcard}" == "${True}" ]; then
        local  folderName="${pathWithWildcard##*/}"

        echo  "${folderName}"
    else
        local  parentPath="${pathWithWildcard%/*}"
        local  leftOfFolderNameWildcard="${leftOfWildcard##*/}"
        pushd  "${parentPath}"  >  /dev/null

        local  lsOutput="$( ls -ld  "${leftOfFolderNameWildcard}"*"${rightOfWildcard}"  2> /dev/null )"
        popd  >  /dev/null
        local  folderNames="$( echo  "${lsOutput}"  |  sed  's/.*[0-9]:[0-9][0-9]  *'"'"'*\([^'"'"']*\)/\1/' )"

        echo  "${folderNames}"  #// Multi lines

        # ls -ld:
        #     Git bash:
        #         drwxr-xr-x 1 user1 123456 0 Jan  1 09:34 'project_ a'
        #         drwxr-xr-x 1 user1 123456 0 Jan  1 12:34  project_1234
        #     CentOS7 bash:
        #         drwxr-xr-x 1 user1 123456 0 Jan  1 09:34 project_ a
        #         drwxr-xr-x 1 user1 123456 0 Jan  1 12:34 project_1234
        # ls -d:
        #     Git bash:
        #         'project_ a'  project_1234
        #     CentOS7 bash:
        #         project_ a
        #         project_1234
    fi
    #ref: https://unix.stackexchange.com/questions/156534/bash-script-error-with-strings-with-paths-that-have-spaces-and-wildcards
    # for f in "${pathWithWildcard}" ; do
    #     echo "$f"   #// Output "project_*"
    # done
}

function  AssertExist() {
    local  path="$1"
    local  leftOfWildcard="${path%\**}"
    if [ "${leftOfWildcard}" == "${path}" ]; then  #// No wildcard

        if [ ! -e "${path}" ]; then
            Error  "Not found \"${path}\""
        fi
    else
        local  rightOfWildcard="${path##*\*}"
        if [ ! -e "${leftOfWildcard}"*"${rightOfWildcard}" ]; then
            Error  "Not found \"${path}\""
        fi
    fi
}

#// pp "$config"
#// pp "$config" config
#// pp "$array" array  ${#array[@]}  "${array[@]}"
#// $( pp "$config" >&2 )
function  pp() {
    local  value="$1"
    local  variableName="$2"
    if [ "${variableName}" != "" ]; then  variableName=" ${variableName} "  ;fi
    local  oldIFS="$IFS"
    IFS=$'\n'
    local  valueLines=( ${value} )
    IFS="$oldIFS"
    if [[ "$(declare -p ${variableName})" =~ "declare -a" ]]; then
        local  type="array"
    elif [ "${#valueLines[@]}" == 1  -o  "${#valueLines[@]}" == 0 ]; then
        local  type="oneLine"
    else
        local  type="multiLine"
    fi

    if [[ "${type}" == "oneLine" ]]; then
        echo  "@@@${variableName}= \"${value}\" ---------------------------"
    elif [[ "${type}" == "multiLine" ]]; then
        echo  "@@@${variableName}---------------------------"
        echo  "\"${value}\""
    elif [[ "${type}" == "array" ]]; then
        echo  "@@@${variableName}---------------------------"
        local  count="$3"
        if [ "${count}" == "" ]; then
            echo  "[0]: \"$4\""
            echo  "[1]: ERROR: pp parameter is too few"
        else
            local  i="0"
            for (( i = 0; i < ${count}; i += 1 ));do
                echo  "[$i]: \"$4\""
                shift
            done
        fi
    else
        echo  "@@@${variableName}? ---------------------------"
    fi
}

function  Error() {
    local  errorMessage="$1"
    local  exitCode="$2"
    if [ "${exitCode}" == "" ]; then  exitCode=2  ;fi

    echo  "ERROR: ${errorMessage}" >&2
    exit  "${exitCode}"
}

True=0
False=1

Main  "$@"
