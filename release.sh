#!/bin/bash

# Current Version: 1.1.0

## How to get and use?
# git clone "https://github.com/hezhijie0327/GFWList2AGH.git" && chmod 0777 ./GFWList2AGH/release.sh && bash ./GFWList2AGH/release.sh

## Function
# Get Data
function GetData() {
    gfwlist_base64=(
        "https://raw.githubusercontent.com/Loukky/gfwlist-by-loukky/master/gfwlist.txt"
        "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
        "https://raw.githubusercontent.com/poctopus/gfwlist-plus/master/gfwlist-plus.txt"
    )
    gfwlist_domain=(
        "https://raw.githubusercontent.com/Loyalsoldier/cn-blocked-domain/release/domains.txt"
        "https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/gh-pages/gfwlist_domain.txt"
        "https://raw.githubusercontent.com/pexcn/gfwlist-extras/master/gfwlist-extras.txt"
    )
    rm -rf ./*.txt ./*.yaml ./Temp && mkdir ./Temp && cd ./Temp
    for gfwlist_base64_task in "${!gfwlist_base64[@]}"; do
        curl -s --connect-timeout 15 "${gfwlist_base64[$gfwlist_base64_task]}" | base64 -d >> ./gfwlist_base64.tmp
    done
    for gfwlist_domain_task in "${!gfwlist_domain[@]}"; do
        curl -s --connect-timeout 15 "${gfwlist_domain[$gfwlist_domain_task]}" >> ./gfwlist_domain.tmp
    done
}
# Analyse Data
function AnalyseData() {
    gfwlist_data=($(cat ./gfwlist_base64.tmp | grep -v "\!\|\%\|\*\|\/\|\@\|\[\|\]" | sed '/^\./d;s/\|//g' > ./gfwlist_data.tmp && cat ./gfwlist_domain.tmp | grep -v "\#" >> ./gfwlist_data.tmp && cat ./gfwlist_data.tmp | grep -v "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | grep "\." | tr -d -c "[:alnum:]\-\.\n" | tr "A-Z" "a-z" | sed '/^$/d' | sort | uniq | awk "{ print $2 }"))
}
# Output Data
function OutputData() {
    gfwlist_dns=(
        "https://doh.opendns.com:443/dns-query"
        "tls://dns.google:853"
    )
    upstream_dns=(
        "https://dns.alidns.com:443/dns-query"
        "https://dns.pub:443/dns-query"
        "tls://dns.alidns.com:853"
        "tls://dns.pub:853"
    )
    for upstream_dns_task in "${!upstream_dns[@]}"; do
        echo "${upstream_dns[$upstream_dns_task]}" >> ../gfwlist2agh_web.txt
        echo "  - ${upstream_dns[$upstream_dns_task]}" >> ../gfwlist2agh_conf.yaml
    done
    for gfwlist_dns_task in "${!gfwlist_dns[@]}"; do
        for gfwlist_data_task in "${!gfwlist_data[@]}"; do
            echo "[/${gfwlist_data[$gfwlist_data_task]}/]${gfwlist_dns[gfwlist_dns_task]}" >> ../gfwlist2agh_web.txt
            echo "  - '[/${gfwlist_data[$gfwlist_data_task]}/]${gfwlist_dns[gfwlist_dns_task]}'" >> ../gfwlist2agh_conf.yaml
        done
    done
    cd .. && rm -rf ./Temp
    exit 0
}

## Process
# Call GetData
GetData
# Call AnalyseData
AnalyseData
# Call OutputData
OutputData
