#!/bin/bash

# Current Version: 1.0.3

## How to get and use?
# git clone "https://github.com/hezhijie0327/GFWList2AGH.git" && chmod 0777 ./GFWList2AGH/release.sh && bash ./GFWList2AGH/release.sh

## Function
# Get Data
function GetData() {
    gfwlist_base64_list_unchecked=(
        "https://raw.githubusercontent.com/Loukky/gfwlist-by-loukky/master/gfwlist.txt"
        "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
        "https://raw.githubusercontent.com/poctopus/gfwlist-plus/master/gfwlist-plus.txt"
    )
    gfwlist_domain_list_unchecked=(
        "https://raw.githubusercontent.com/Loyalsoldier/cn-blocked-domain/release/domains.txt"
        "https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/gh-pages/gfwlist_domain.txt"
        "https://raw.githubusercontent.com/pexcn/gfwlist-extras/master/gfwlist-extras.txt"
    )
    rm -rf *.txt *.yaml ./Temp && mkdir ./Temp && cd ./Temp
    for gfwlist_base64_list_unchecked_task in "${!gfwlist_base64_list_unchecked[@]}"; do
        echo "Downloading GFWList base64 list ($((${gfwlist_base64_list_unchecked_task} + 1)) / ${#gfwlist_base64_list_unchecked[@]})"
        curl -s --connect-timeout 15 "${gfwlist_base64_list_unchecked[$gfwlist_base64_list_unchecked_task]}" | base64 -d >> ./gfwlist_base64_list_unchecked.tmp
        sleep 10s
    done
    for gfwlist_domain_list_unchecked_task in "${!gfwlist_domain_list_unchecked[@]}"; do
        echo "Downloading GFWList domain list ($((${gfwlist_domain_list_unchecked_task} + 1)) / ${#gfwlist_domain_list_unchecked[@]})"
        curl -s --connect-timeout 15 "${gfwlist_domain_list_unchecked[$gfwlist_domain_list_unchecked_task]}" >> ./gfwlist_domain_list_unchecked.tmp
        sleep 10s
    done
}
# Check Data
function CheckData() {
    cat ./gfwlist_base64_list_unchecked.tmp ./gfwlist_domain_list_unchecked.tmp | grep -v "\!\|\#\|\:\|\[\|\]" | sed 's/%.*//g;s/\*.*//g;s/\/.*//g;s/\|//g;s/^\.//g;s/^||\?//g;s/http\?:\/\///g;s/https\?:\/\///g' > ./gfwlist_checked.tmp
}
# Output Data
function OutputData() {
    gfwlist_data=($(awk "{ print $2 }" ./gfwlist_checked.tmp | sed '/\.$/d;/^!.*/d;/^$/d;/^@.*/d;/^[0-9\.]*$/d;/^[^\.]*$/d;/^\[.*/d' | sort | uniq))
    gfwlist_dns=(
        "https://doh.opendns.com:443/dns-query"
    )
    upstream_dns=(
        "https://dns.alidns.com:443/dns-query"
    )
    for upstream_dns_task in "${!upstream_dns[@]}"; do
        echo "${upstream_dns[$upstream_dns_task]}" >> ../upstream.txt
        echo "  - ${upstream_dns[$upstream_dns_task]}" >> ../upstream.yaml
    done
    for gfwlist_dns_task in "${!gfwlist_dns[@]}"; do
        for gfwlist_data_task in "${!gfwlist_data[@]}"; do
            echo "[/${gfwlist_data[$gfwlist_data_task]}/]${gfwlist_dns[gfwlist_dns_task]}" >> ../upstream.txt
            echo "  - '[/${gfwlist_data[$gfwlist_data_task]}/]${gfwlist_dns[gfwlist_dns_task]}'" >> ../upstream.yaml
        done
    done
    cd .. && rm -rf ./Temp
    exit 0
}

## Process
# Call GetData
GetData
# Call CheckData
CheckData
# Call OutputData
OutputData
