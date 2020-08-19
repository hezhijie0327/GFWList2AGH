#!/bin/bash

# Current Version: 1.0.9

## How to get and use?
# git clone "https://github.com/hezhijie0327/GFWList2AGH.git" && chmod 0777 ./GFWList2AGH/AdGuardHome.sh && bash ./GFWList2AGH/AdGuardHome.sh

## Function
# Analyse Configuration File
function AnalyseConfigurationFile() {
    get_root=$(cd $(dirname "$0"); pwd)
    get_bind_host_line="1"
    get_upstream_dns_line=$(cat -n ${get_root}/AdGuardHome.yaml | grep "upstream\_dns" | awk '{ print $1 }')
    get_bootstrap_dns_line=$(cat -n ${get_root}/AdGuardHome.yaml | grep "bootstrap\_dns" | awk '{ print $1 }')
    get_schema_version_line=$(cat -n ${get_root}/AdGuardHome.yaml | grep "schema\_version" | awk '{ print $1 }')
}
# Split Configuration File
function SplitConfigurationFile() {
    configuration_part_1=$(cat ${get_root}/AdGuardHome.yaml | head -n ${get_upstream_dns_line} | tail -n +${get_bind_host_line})
    configuration_part_2=$(cat ${get_root}/AdGuardHome.yaml | head -n ${get_schema_version_line} | tail -n +${get_bootstrap_dns_line})
}
# Get GFWList2AGH Data
function GetGFWList2AGHData() {
    gfwlist2agh_data=$(curl -s --connect-timeout 15 "https://source.zhijie.online/GFWList2AGH/master/gfwlist2agh_gfwlist.yaml")
}
# Output Configuration File
function OutputConfigurationFile() {
    echo "${configuration_part_1}" > ${get_root}/AdGuardHome.yaml
    echo "${gfwlist2agh_data}" >> ${get_root}/AdGuardHome.yaml
    echo "${configuration_part_2}" >> ${get_root}/AdGuardHome.yaml
}
# Apply Configuration File
function ApplyConfigurationFile() {
    adguardhome_pid=$(ps -ef | grep "AdGuardHome" | grep -v "grep" | awk '{ print $2 }')
    if [ "${adguardhome_pid}" == "" ]; then
        systemctl start AdGuardHome.service
        exit 0
    else
        systemctl restart AdGuardHome.service
        exit 0
    fi
}

## Process
# Call AnalyseConfigurationFile
AnalyseConfigurationFile
# Call SplitConfigurationFile
SplitConfigurationFile
# Call GetGFWList2AGHData
GetGFWList2AGHData
# Call OutputConfigurationFile
OutputConfigurationFile
# Call ApplyConfigurationFile
ApplyConfigurationFile
