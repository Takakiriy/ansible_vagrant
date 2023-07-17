#!/bin/bash

SubNetIP="192.168.34."
PortUpperNumber="23"
VMNamePrefix="centos7_"

function  Main() {
    local  configurationTo="$1"
    local  configurationFrom="__"
    if [ "${configurationTo}" == "" ]; then
        local  configurationTo="51"
    fi

    ChangeTheConfiguration  "${configurationFrom}"  "${configurationTo}"
    ./install.sh  port  > /dev/null  2>&1
    echo  ""
    echo  "ErrorCount: ${ErrorCount}"
}

#// ChangeTheConfiguration
#// Parameters:
#//     $1, $2: lower port number. e.g.) 51, 52, 53, ...
function  ChangeTheConfiguration() {
    local  configurationFrom="$1"
    local  configurationTo="$2"
    local  vmNameSuffixFrom="$3"
    local  vmNameSuffixTo="$4"
    if [ "${vmNameSuffixFrom}" == "" ]; then  vmNameSuffixFrom="${configurationFrom}"  ;fi
    if [ "${vmNameSuffixTo}"   == "" ]; then  vmNameSuffixTo="${configurationTo}"  ;fi

    echo  "Change the configuration from \"${configurationFrom}\" to \"${configurationTo}\""

    SetSettingsInREADME       "./README.yaml"      0  "${configurationFrom}" "${configurationTo}"
    SetSettingsInInstallSh    "./install.sh"       0  "${configurationFrom}" "${configurationTo}"
    SetSettingsInVagrantfile  "./Vagrantfile"      0  "${configurationFrom}" "${configurationTo}"
    SetSettingsInRunPlaybook  "./run_playbook.sh"  0  "${configurationFrom}" "${configurationTo}"

    SetVMNameInInstallSh    "./install.sh"       0  "${vmNameSuffixFrom}" "${vmNameSuffixTo}"
    SetVMNameInVagrantfile  "./Vagrantfile"      0  "${vmNameSuffixFrom}" "${vmNameSuffixTo}"
    SetVMNameInRunPlaybook  "./run_playbook.sh"  0  "${vmNameSuffixFrom}" "${vmNameSuffixTo}"
    SetVMNameInVars         "./vars.yml"         0  "${vmNameSuffixFrom}" "${vmNameSuffixTo}"
}

function  SetSettingsInREADME() {
    local  filePath="$1"
    local  lineNum="$2"
    local  configurationFrom="$3"
    local  configurationTo="$4"

    local  service="README"
    local  settingFrom="${configurationFrom}"
    local  settingTo="${configurationTo}"
    local  errorCountAtStarting="${ErrorCount}"

    #// [localhost]:2351
    SetPortSetting  "${filePath}"  11  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${SubNetIP}"  "${configurationTo}"
    SetPortSetting  "${filePath}"  12  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${PortUpperNumber}"  "${configurationTo}"
    SetPortSetting  "${filePath}"  94  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${PortUpperNumber}"  "${configurationTo}"
    SetPortSetting  "${filePath}"  98  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${PortUpperNumber}"  "${configurationTo}"
    if [ "${ErrorCount}" != "${errorCountAtStarting}" ]; then
        ShowHintToEditReplaceSettings  "${filePath}"  "${lineNum}"  "${service}"  "${FUNCNAME[0]}"  "${lineNum}" \
            "\(${PortUpperNumber}\|${SubNetIP}\)"
    fi
}

function  SetSettingsInInstallSh() {
    local  filePath="$1"
    local  lineNum="$2"
    local  configurationFrom="$3"
    local  configurationTo="$4"

    local  service="install.sh"
    local  settingFrom="${configurationFrom}"
    local  settingTo="${configurationTo}"
    local  errorCountAtStarting="${ErrorCount}"

    SetPortSetting  "${filePath}"   7  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${PortUpperNumber}"  "${configurationTo}"
    if [ "${ErrorCount}" != "${errorCountAtStarting}" ]; then
        ShowHintToEditReplaceSettings  "${filePath}"  "${lineNum}"  "${service}"  "${FUNCNAME[0]}"  "${lineNum}" \
            "\(${PortUpperNumber}\|${SubNetIP}\)"
    fi
}

function  SetVMNameInInstallSh() {
    local  filePath="$1"
    local  lineNum="$2"
    local  configurationFrom="$3"
    local  configurationTo="$4"

    local  service="install.sh"
    local  settingFrom="${configurationFrom}"
    local  settingTo="${configurationTo}"
    local  errorCountAtStarting="${ErrorCount}"

    SetPortSetting  "${filePath}"   5  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${VMNamePrefix}"  "${configurationTo}"
    if [ "${ErrorCount}" != "${errorCountAtStarting}" ]; then
        ShowHintToEditReplaceSettings  "${filePath}"  "${lineNum}"  "${service}"  "${FUNCNAME[0]}"  "${lineNum}" \
            "\(${VMNamePrefix}\)"
    fi
}

function  SetSettingsInVagrantfile() {
    local  filePath="$1"
    local  lineNum="$2"
    local  configurationFrom="$3"
    local  configurationTo="$4"

    local  service="Vagrantfile"
    local  settingFrom="${configurationFrom}"
    local  settingTo="${configurationTo}"
    local  errorCountAtStarting="${ErrorCount}"

    SetPortSetting  "${filePath}"  15  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${SubNetIP}"  "${configurationTo}"
    SetPortSetting  "${filePath}"  16  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${PortUpperNumber}"  "${configurationTo}"
    SetPortSetting  "${filePath}"  33  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${SubNetIP}"  "${configurationTo}"
    if [ "${ErrorCount}" != "${errorCountAtStarting}" ]; then
        ShowHintToEditReplaceSettings  "${filePath}"  "${lineNum}"  "${service}"  "${FUNCNAME[0]}"  "${lineNum}" \
            "\(${PortUpperNumber}\|${SubNetIP}\)"
    fi
}

function  SetVMNameInVagrantfile() {
    local  filePath="$1"
    local  lineNum="$2"
    local  configurationFrom="$3"
    local  configurationTo="$4"

    local  service="Vagrantfile"
    local  settingFrom="${configurationFrom}"
    local  settingTo="${configurationTo}"
    local  errorCountAtStarting="${ErrorCount}"

    SetPortSetting  "${filePath}"  12  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${VMNamePrefix}"  "${configurationTo}"
    SetPortSetting  "${filePath}"  33  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${VMNamePrefix}"  "${configurationTo}"
    if [ "${ErrorCount}" != "${errorCountAtStarting}" ]; then
        ShowHintToEditReplaceSettings  "${filePath}"  "${lineNum}"  "${service}"  "${FUNCNAME[0]}"  "${lineNum}" \
            "\(${VMNamePrefix}\)"
    fi
}

function  SetSettingsInRunPlaybook() {
    local  filePath="$1"
    local  lineNum="$2"
    local  configurationFrom="$3"
    local  configurationTo="$4"

    local  service="run_playbook.sh"
    local  settingFrom="${configurationFrom}"
    local  settingTo="${configurationTo}"
    local  errorCountAtStarting="${ErrorCount}"

    SetPortSetting  "${filePath}"  3  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${PortUpperNumber}"  "${configurationTo}"
    if [ "${ErrorCount}" != "${errorCountAtStarting}" ]; then
        ShowHintToEditReplaceSettings  "${filePath}"  "${lineNum}"  "${service}"  "${FUNCNAME[0]}"  "${lineNum}" \
            "\(${PortUpperNumber}\|${SubNetIP}\)"
    fi
}

function  SetVMNameInRunPlaybook() {
    local  filePath="$1"
    local  lineNum="$2"
    local  configurationFrom="$3"
    local  configurationTo="$4"

    local  service="run_playbook.sh"
    local  settingFrom="${configurationFrom}"
    local  settingTo="${configurationTo}"
    local  errorCountAtStarting="${ErrorCount}"

    SetPortSetting  "${filePath}"   2  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${VMNamePrefix}"  "${configurationTo}"
    SetPortSetting  "${filePath}"   3  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${VMNamePrefix}"  "${configurationTo}"
    SetPortSetting  "${filePath}"  24  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${VMNamePrefix}"  "${configurationTo}"
    SetPortSetting  "${filePath}"  25  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${VMNamePrefix}"  "${configurationTo}"
    if [ "${ErrorCount}" != "${errorCountAtStarting}" ]; then
        ShowHintToEditReplaceSettings  "${filePath}"  "${lineNum}"  "${service}"  "${FUNCNAME[0]}"  "${lineNum}" \
            "\(${VMNamePrefix}\)"
    fi
}

function  SetVMNameInVars() {
    local  filePath="$1"
    local  lineNum="$2"
    local  configurationFrom="$3"
    local  configurationTo="$4"

    local  service="Vagrantfile"
    local  settingFrom="${configurationFrom}"
    local  settingTo="${configurationTo}"
    local  errorCountAtStarting="${ErrorCount}"

    SetPortSetting  "${filePath}"  1  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${FUNCNAME[0]}"  "${lineNum}" \
        "${VMNamePrefix}"  "${configurationTo}"
    if [ "${ErrorCount}" != "${errorCountAtStarting}" ]; then
        ShowHintToEditReplaceSettings  "${filePath}"  "${lineNum}"  "${service}"  "${FUNCNAME[0]}"  "${lineNum}" \
            "\(${VMNamePrefix}\)"
    fi
}

# SetSetting
#    Arguments are a field name and colon ($8) and its value ($9)
function  SetPortSetting() {
    local  filePath="$1"
    local  lineNum="$2"
    local  service="$3"
    local  configurationFrom="$4"
    local  settingFrom="$5"
    local  configurationTo="$6"
    local  settingTo="$7"
    local  changerFunctionName="$8"
    local  changerLineNum="$9"
    shift
    local  startsWith="$9"
    shift
    local  value="$9"  #// $10
    shift
    local  displayableValue="$9"  #// $11

    local  regularExpression="$( echo "${startsWith}" | sed 's/\./\\./g' )[0-9]*"
    local  sedReplaceTo="${startsWith}${value}"
    if [ "${displayableValue}" != "" ]; then
        local  displayableReplaceTo="${startsWith}${displayableValue}"
    else
        local  displayableReplaceTo=""
    fi

    EditSetting  "${filePath}"  "${lineNum}"  "${service}"  "${configurationFrom}"  "${settingFrom}"  "${configurationTo}"  "${settingTo}"  "${changerFunctionName}"  "${changerLineNum}" \
        "${regularExpression}"  "${sedReplaceTo}"  "${displayableReplaceTo}"
}

# EditSetting
#    Arguments $9 and $10 are same as sed command parameters without -e option
function  EditSetting() {
    local  filePath="$1"
    local  lineNum="$2"
    local  service="$3"
    local  configurationFrom="$4"
    local  settingFrom="$5"
    local  configurationTo="$6"
    local  settingTo="$7"
    local  changerFunctionName="$8"
    local  changerLineNum="$9"
    shift
    local  regularExpression="$9"
    shift
    local  sedReplaceTo="$9"  #// $10
    shift
    local  displayableReplaceTo="$9"  #// $11

    local  unescapedReplaceTo="$( echo "${sedReplaceTo}" |
        sed -e 's/\\\\n/\\n/g' | sed -e 's/\\\//\//g' | sed -e 's/\\\./\./g' |
        sed -e 's/\\\\/\\/g' | sed -e 's/\\&/\&/g' )"
    unescapedReplaceTo="$( echo "${unescapedReplaceTo}" | sed -e 's/^\\[1-9]//' )"
    if [ "${displayableReplaceTo}" == "" ]; then
        displayableReplaceTo="${unescapedReplaceTo}"
    fi

    echo  "${filePath}:${lineNum}: ${displayableReplaceTo}  #// ${service}: Change a setting from \"${settingFrom}\" to \"${settingTo}\" by ${changerFunctionName} ${changerLineNum} function"

    #// Check
    local  line=$( sed -n ${lineNum}P "${filePath}")
    local  found="${False}"

    echo "${line}" | grep "${regularExpression}" > /dev/null  &&  found="${True}"
    if [ "${found}" == "${False}" ]; then

        if [[ "${line}" != *"${unescapedReplaceTo}"* ]]; then
            echo  "${filePath}:${lineNum}: ${line}  #// Current contents"
            echo  ""
            Error  "    ${changerFunctionName} ${changerLineNum}: ERROR: not matched pattern \"${regularExpression}\" or not contains \"${unescapedReplaceTo}\""
            return
        fi
    fi

    #// Replace
    local  text="$(sed "${lineNum} s/${regularExpression}/${sedReplaceTo}/g" "${filePath}" )"
    if [ "${text}" != "" ]; then
        echo "${text}" > "${filePath}"
    fi
}

function  EchoOtherCase() {
    local  filePath="$1"
    local  lineNum="$2"
    local  service="$3"
    local  configurationFrom="$4"
    local  settingFrom="$5"
    local  configurationTo="$6"
    local  settingTo="$7"
    local  changerFunctionName="$8"
    local  changerLineNum="$9"

    if [ "${settingFrom}" != ""  -a  "${settingTo}" != "" ]; then
        if [ "${settingFrom}" == "${settingTo}" ]; then
            echo "${filePath}:${lineNum}: ${service}: No changed setting (${settingTo}) by ${changerFunctionName} ${changerLineNum} function"
        else
            echo "ERROR: Not defined edit script in ${changerFunctionName} ${changerLineNum} function for setting from \"${settingFrom}\" to \"${settingTo}\""
        fi
    else
        if [ "${settingFrom}" == "" ]; then
            Error "ERROR: Not defined configuration name \"${configurationFrom}\" in ${changerFunctionName} ${changerLineNum} function"
        fi
        if [ "${settingTo}" == "" ]; then
            Error "ERROR: Not defined configuration name \"${configurationTo}\" in ${changerFunctionName} ${changerLineNum} function"
        fi
    fi
}

function  ShowHintToEditReplaceSettings() {
    local  filePath="$1"
    local  firstLineNum="$2"
    local  service="$3"
    local  changerFunctionName="$4"
    local  changerLineNum="$5"
    local  regularExpression="$6"
    echo  ""
    echo  "    ${changerFunctionName} ${changerLineNum}: INFO: grep '${regularExpression}'  \"${filePath}\"  #// Hint to edit replace settings"

    local  grepOutput="$( grep -n  "${regularExpression}"  "${filePath}" )"
    local  oldIFS="$IFS"
    IFS=$'\n'
    local  lineNunbers=( $( echo  "${grepOutput}"  |  grep -o  '^[0-9][0-9]*' ) )
    local  grepOutputArray=( ${grepOutput} )
    IFS="$oldIFS"
    for (( i = 0; i < ${#grepOutputArray[@]}; i += 1 ));do
        local  lineNum="${lineNunbers[$i]}"
        local  offset=$(( ${lineNum} - ${firstLineNum} ))
        local  lineNumAndOffset="${lineNum}(=${firstLineNum}+${offset})"
        local  lineContents="$( echo  "${grepOutputArray[$i]}"  |  grep -o ":.*" )"

        echo  "        ${lineNumAndOffset}${lineContents}"
    done
    echo  ""
}

function  TestMain() {
    ChangeTheConfiguration  "debug"  "release"
    ChangeTheConfiguration  "release"  "debug"
}

function  TestOfWarning() {
    local  configurationFrom="debug"
    local  configurationTo="release"

    local  service_T_filePath="./service_T.yaml"
    TestOfWarningSub  "${service_T_filePath}"  22  "${configurationFrom}" "${configurationTo}"
}

function SetLastOf() {
    local  input="$1"
    local  last="$2"

    if [ "${input:${#input}-${#last}:${#last}}" == "${last}" ]; then
        echo  "${input}"
    else
        echo  "${input}${last}"
    fi
}

#// _Get
#// Example:
#//    object=(keyA "1" keyB "x")
#//    echo "$(_Get "${object[@]}" keyB )"
function  _Get() {
    local  objectName="${1}"
    local  key="$2"
    local  operation=""

    operation="_GetSub \"\${${objectName}[@]}\" \"${key}\""
    eval "${operation}"
}

function  _GetSub() {
    local  objectEntries=("${@}")
    local  keyIndex=$(( ${#objectEntries[@]} - 1 ))
    local  key="${objectEntries[${keyIndex}]}"
    local  value=""

    for (( i = 0; i < "${keyIndex}"; i += 2 ));do
        if [ "${objectEntries[${i}]}" == "${key}" ]; then
            value="${objectEntries[${i}+1]}"
        fi
    done

    echo "${value}"
}

#// _Set
#// Example:
#//    object=(keyA "1" keyB "x")
#//    eval "$(_Set object keyB "y" )"
function  _Set() {
    local  objectName="${1}"
    local  key="$2"
    local  value="$3"
    local  operation=""

    operation="_SetSub \"\${${objectName}[@]}\" \"${objectName}\" \"${key}\" \"${value}\""
    eval "${operation}"
}

function  _SetSub() {
    local  objectEntries=("${@}")
    local  count=${#objectEntries[@]}
    local  objectNameIndex=$(( ${count} - 3 ))
    local  keyIndex=$(( ${count} - 2 ))
    local  valueIndex=$(( ${count} - 1 ))
    local  objectName="${objectEntries[${objectNameIndex}]}"
    local  key="${objectEntries[${keyIndex}]}"
    local  value="${objectEntries[${valueIndex}]}"
    local  command=""

    for (( i = 0; i < "${keyIndex}"; i += 2 ));do
        if [ "${objectEntries[${i}]}" == "${key}" ]; then

            command="${objectName}[$(( ${i} + 1 ))]=\"${value}\""
        fi
    done
    if [ "${command}" == "" ]; then
        local  newKeyIndex=$(( ${count} - 3 ))
        local  newValueIndex=$(( ${count} - 2 ))

        command="${objectName}[${newKeyIndex}]=\"${key}\"; ${objectName}[${newValueIndex}]=\"${value}\""
    fi

    echo "${command}"
}

function  Error() {
    local  errorMessage="$1"

    echo  "${errorMessage}"
    ErrorCount=$(( ${ErrorCount} + 1 ))
}
ErrorCount=0

True=0
False=1

Main  "$@"
