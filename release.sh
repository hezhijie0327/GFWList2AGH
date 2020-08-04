#!/bin/bash

# Current Version: 1.2.0

## How to get and use?
# git clone "https://github.com/hezhijie0327/GFWList2AGH.git" && chmod 0777 ./GFWList2AGH/release.sh && bash ./GFWList2AGH/release.sh

## Function
# Get Data
function GetData() {
    cnacc_domain=(
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf"
        "https://raw.githubusercontent.com/hezhijie0327/GFWList2AGH/master/data/data_cnacc.txt"
    )
    dead_domain=(
        "https://raw.githubusercontent.com/hezhijie0327/DHDb/master/dhdb_dead.txt"
    )
    gfwlist_base64=(
        "https://raw.githubusercontent.com/Loukky/gfwlist-by-loukky/master/gfwlist.txt"
        "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
        "https://raw.githubusercontent.com/poctopus/gfwlist-plus/master/gfwlist-plus.txt"
    )
    gfwlist_domain=(
        "https://raw.githubusercontent.com/Loyalsoldier/cn-blocked-domain/release/domains.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt"
        "https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/gh-pages/gfwlist_domain.txt"
        "https://raw.githubusercontent.com/hezhijie0327/GFWList2AGH/master/data/data_gfwlist.txt"
        "https://raw.githubusercontent.com/pexcn/gfwlist-extras/master/gfwlist-extras.txt"
    )
    rm -rf ./*.txt ./*.yaml ./Temp && mkdir ./Temp && cd ./Temp
    for cnacc_domain_task in "${!cnacc_domain[@]}"; do
        curl -s --connect-timeout 15 "${cnacc_domain[$cnacc_domain_task]}" >> ./cnacc_domain.tmp
    done
    for dead_domain_task in "${!dead_domain[@]}"; do
        curl -s --connect-timeout 15 "${dead_domain[$dead_domain_task]}" >> ./dead_domain.tmp
    done
    for gfwlist_base64_task in "${!gfwlist_base64[@]}"; do
        curl -s --connect-timeout 15 "${gfwlist_base64[$gfwlist_base64_task]}" | base64 -d >> ./gfwlist_base64.tmp
    done
    for gfwlist_domain_task in "${!gfwlist_domain[@]}"; do
        curl -s --connect-timeout 15 "${gfwlist_domain[$gfwlist_domain_task]}" >> ./gfwlist_domain.tmp
    done
}
# Analyse Data
function AnalyseData() {
    cnacc_data=($(cat ./cnacc_domain.tmp | grep -v "\#" | sed 's/\/114\.114\.114\.114//g;s/server\=\///g' > ./cnacc_data.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./dead_domain.tmp ./cnacc_data.tmp > ./cnacc_data.temp && cat ./cnacc_data.temp | grep -v "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | grep "\." | tr -d -c "[:alnum:]\-\.\n" | tr "A-Z" "a-z" | sed '/^$/d' | sort | uniq | awk "{ print $2 }"))
    gfwlist_data=($(cat ./gfwlist_base64.tmp | grep -v "\!\|\%\|\*\|\/\|\@\|\[\|\]" | sed '/^\./d;s/\|//g' > ./gfwlist_data.tmp && cat ./gfwlist_domain.tmp | grep -v "\#\|\[\|\\$\|\]\|\^\|{\|}" >> ./gfwlist_data.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./dead_domain.tmp ./gfwlist_data.tmp > ./gfwlist_data.temp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./cnacc_data.temp ./gfwlist_data.temp | grep -v "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | grep "\." | tr -d -c "[:alnum:]\-\.\n" | tr "A-Z" "a-z" | sed '/^$/d' | sort | uniq | awk "{ print $2 }"))
}
# Output Data
function OutputData() {
    cnacc_dns=(
        "https://dns.alidns.com:443/dns-query"
        "tls://dns.alidns.com:853"
    )
    gfwlist_dns=(
        "https://doh.opendns.com:443/dns-query"
        "tls://dns.google:853"
    )
    upstream_dns=(
        "https://dns.alidns.com:443/dns-query"
        "tls://dns.alidns.com:853"
    )
    for upstream_dns_task in "${!upstream_dns[@]}"; do
        echo "${upstream_dns[$upstream_dns_task]}" >> ../gfwlist2agh_web.txt
        echo "  - ${upstream_dns[$upstream_dns_task]}" >> ../gfwlist2agh_conf.yaml
    done
    for cnacc_dns_task in "${!cnacc_dns[@]}"; do
        for cnacc_data_task in "${!cnacc_data[@]}"; do
            echo "[/${cnacc_data[$cnacc_data_task]}/]${cnacc_dns[cnacc_dns_task]}" >> ../gfwlist2agh_web.txt
            echo "  - '[/${cnacc_data[$cnacc_data_task]}/]${cnacc_dns[cnacc_dns_task]}'" >> ../gfwlist2agh_conf.yaml
        done
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
