#!/bin/bash

# Current Version: 1.4.1

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
        "https://raw.githubusercontent.com/pexcn/gfwlist-extras/master/gfwlist-extras.txt"
    )
    rm -rf ./gfwlist2agh_* ./Temp && mkdir ./Temp && cd ./Temp
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
    cnacc_data=($(cat ./cnacc_domain.tmp ../data/data_cnacc.txt | sed 's/\/114\.114\.114\.114//g;s/server\=\///g' | tr "A-Z" "a-z" | grep -E "^(([a-z]{1})|([a-z]{1}[a-z]{1})|([a-z]{1}[0-9]{1})|([0-9]{1}[a-z]{1})|([a-z0-9][-_\.a-z0-9]{1,61}[a-z0-9]))\.([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$" | sort | uniq > ./cnacc_data.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./dead_domain.tmp ./cnacc_data.tmp > ./cnacc_alive.tmp && cat ./gfwlist_base64.tmp ./gfwlist_domain.tmp ../data/data_gfwlist.txt | tr -d "|" | tr "A-Z" "a-z" | grep -E "^(([a-z]{1})|([a-z]{1}[a-z]{1})|([a-z]{1}[0-9]{1})|([0-9]{1}[a-z]{1})|([a-z0-9][-_\.a-z0-9]{1,61}[a-z0-9]))\.([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$" | sort | uniq > gfwlist_data.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./dead_domain.tmp ./gfwlist_data.tmp > ./gfwlist_alive.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./gfwlist_alive.tmp ./cnacc_alive.tmp | awk "{ print $2 }"))
    gfwlist_data=($(awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./cnacc_alive.tmp ./gfwlist_alive.tmp | awk "{ print $2 }"))
}
# Output Data
function OutputData() {
    cnacc_dns=(
        "https://dns.pub:443/dns-query"
        "tls://dns.alidns.com:853"
    )
    combine_dns=(
        "https://dns.alidns.com:443/dns-query"
        "tls://dns.pub:853"
    )
    gfwlist_dns=(
        "https://doh.opendns.com:443/dns-query"
        "tls://dns.google:853"
    )
    for (( upstream_dns_task = 0; upstream_dns_task < 3; upstream_dns_task++ )); do
        case ${upstream_dns_task} in
            0)
            for cnacc_upstream_dns_task in "${!gfwlist_dns[@]}"; do
                echo "${gfwlist_dns[$cnacc_upstream_dns_task]}" >> ../gfwlist2agh_cnacc.txt
                echo "  - ${gfwlist_dns[$cnacc_upstream_dns_task]}" >> ../gfwlist2agh_cnacc.yaml
            done
            ;;
            1)
            for combine_upstream_dns_task in "${!combine_dns[@]}"; do
                echo "${combine_dns[$combine_upstream_dns_task]}" >> ../gfwlist2agh_combine.txt
                echo "  - ${combine_dns[$combine_upstream_dns_task]}" >> ../gfwlist2agh_combine.yaml
            done
            ;;
            2)
            for gfwlist_upstream_dns_task in "${!cnacc_dns[@]}"; do
                echo "${cnacc_dns[$gfwlist_upstream_dns_task]}" >> ../gfwlist2agh_gfwlist.txt
                echo "  - ${cnacc_dns[$gfwlist_upstream_dns_task]}" >> ../gfwlist2agh_gfwlist.yaml
            done
            ;;
        esac
    done
    for cnacc_dns_task in "${!cnacc_dns[@]}"; do
        echo -n "[/" >> ../gfwlist2agh_cnacc.txt
        echo -n "[/" >> ../gfwlist2agh_combine.txt
        echo -n "  - '[/" >> ../gfwlist2agh_cnacc.yaml
        echo -n "  - '[/" >> ../gfwlist2agh_combine.yaml
        for cnacc_data_task in "${!cnacc_data[@]}"; do
            echo -n "${cnacc_data[$cnacc_data_task]}/" >> ../gfwlist2agh_cnacc.txt
            echo -n "${cnacc_data[$cnacc_data_task]}/" >> ../gfwlist2agh_combine.txt
            echo -n "${cnacc_data[$cnacc_data_task]}/" >> ../gfwlist2agh_cnacc.yaml
            echo -n "${cnacc_data[$cnacc_data_task]}/" >> ../gfwlist2agh_combine.yaml
        done
        echo -e "]${cnacc_dns[cnacc_dns_task]}" >> ../gfwlist2agh_cnacc.txt
        echo -e "]${cnacc_dns[cnacc_dns_task]}" >> ../gfwlist2agh_combine.txt
        echo -e "]${cnacc_dns[cnacc_dns_task]}'" >> ../gfwlist2agh_cnacc.yaml
        echo -e "]${cnacc_dns[cnacc_dns_task]}'" >> ../gfwlist2agh_combine.yaml
    done
    for gfwlist_dns_task in "${!gfwlist_dns[@]}"; do
        echo -n "[/" >> ../gfwlist2agh_combine.txt
        echo -n "[/" >> ../gfwlist2agh_gfwlist.txt
        echo -n "  - '[/" >> ../gfwlist2agh_combine.yaml
        echo -n "  - '[/" >> ../gfwlist2agh_gfwlist.yaml
        for gfwlist_data_task in "${!gfwlist_data[@]}"; do
            echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> ../gfwlist2agh_combine.txt
            echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> ../gfwlist2agh_gfwlist.txt
            echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> ../gfwlist2agh_combine.yaml
            echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> ../gfwlist2agh_gfwlist.yaml
        done
        echo -e "]${gfwlist_dns[gfwlist_dns_task]}" >> ../gfwlist2agh_combine.txt
        echo -e "]${gfwlist_dns[gfwlist_dns_task]}" >> ../gfwlist2agh_gfwlist.txt
        echo -e "]${gfwlist_dns[gfwlist_dns_task]}'" >> ../gfwlist2agh_combine.yaml
        echo -e "]${gfwlist_dns[gfwlist_dns_task]}'" >> ../gfwlist2agh_gfwlist.yaml
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
