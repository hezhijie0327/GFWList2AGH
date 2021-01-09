#!/bin/bash

# Current Version: 1.6.8

## How to get and use?
# git clone "https://github.com/hezhijie0327/GFWList2AGH.git" && bash ./GFWList2AGH/release.sh

## Function
# Get Data
function GetData() {
    cnacc_domain=(
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/apple-cn.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/google-cn.txt"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf"
        "https://raw.githubusercontent.com/hezhijie0327/V2SiteDAT/main/direct.txt"
    )
    dead_domain=(
        "https://raw.githubusercontent.com/hezhijie0327/DHDb/master/dhdb_dead.txt"
    )
    gfwlist_base64=(
        "https://raw.githubusercontent.com/Loukky/gfwlist-by-loukky/master/gfwlist.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/domain-list-custom/release/gfwlist.txt"
        "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
        "https://raw.githubusercontent.com/poctopus/gfwlist-plus/master/gfwlist-plus.txt"
    )
    gfwlist_domain=(
        "https://raw.githubusercontent.com/Loyalsoldier/cn-blocked-domain/release/domains.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt"
        "https://raw.githubusercontent.com/cokebar/gfwlist2dnsmasq/gh-pages/gfwlist_domain.txt"
        "https://raw.githubusercontent.com/hezhijie0327/V2SiteDAT/main/proxy.txt"
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
    cnacc_data=($(cat ../data/data_cnacc.txt | grep "\@" | tr -d "\@" > ./cnacc_addition.tmp && cat ../data/data_gfwlist.txt | grep "\@" | tr -d "\@" > ./gfwlist_addition.tmp && cat ../data/data_cnacc.txt | grep "\!" | tr -d "\!" > ./cnacc_subtraction.tmp && cat ../data/data_gfwlist.txt | grep "\!" | tr -d "\!" > ./gfwlist_subtraction.tmp && cat ./cnacc_domain.tmp ../data/data_cnacc.txt | sed "s/\/114\.114\.114\.114//g;s/server\=\///g" | tr "A-Z" "a-z" | grep -E "^(([a-z]{1})|([a-z]{1}[a-z]{1})|([a-z]{1}[0-9]{1})|([0-9]{1}[a-z]{1})|([a-z0-9][-_\.a-z0-9]{1,61}[a-z0-9]))\.([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$" | sort | uniq > ./cnacc_checklist.tmp && cat ./gfwlist_base64.tmp ./gfwlist_domain.tmp ../data/data_gfwlist.txt | sed "s/http\:\/\///g;s/https\:\/\///g" | tr -d "|" | tr "A-Z" "a-z" | grep -E "^(([a-z]{1})|([a-z]{1}[a-z]{1})|([a-z]{1}[0-9]{1})|([0-9]{1}[a-z]{1})|([a-z0-9][-_\.a-z0-9]{1,61}[a-z0-9]))\.([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$" | sort | uniq > gfwlist_checklist.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./dead_domain.tmp ./cnacc_checklist.tmp > ./cnacc_alive.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./dead_domain.tmp ./gfwlist_checklist.tmp > ./gfwlist_alive.tmp && cat ./cnacc_alive.tmp ./cnacc_addition.tmp | sort | uniq > ./cnacc_added.tmp && cat ./gfwlist_alive.tmp ./gfwlist_addition.tmp | sort | uniq > ./gfwlist_added.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./cnacc_subtraction.tmp ./cnacc_added.tmp > ./cnacc_subtracted.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./gfwlist_subtraction.tmp ./gfwlist_added.tmp > ./gfwlist_subtracted.tmp && cat ./cnacc_subtracted.tmp | rev | cut -d "." -f 1,2 | rev | sort | uniq > ./lite_cnacc_subtracted.tmp && cat ./gfwlist_subtracted.tmp | rev | cut -d "." -f 1,2 | rev | sort | uniq > ./lite_gfwlist_subtracted.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./gfwlist_subtracted.tmp ./cnacc_subtracted.tmp > ./cnacc_data.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./cnacc_subtracted.tmp ./gfwlist_subtracted.tmp > ./gfwlist_data.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./lite_gfwlist_subtracted.tmp ./lite_cnacc_subtracted.tmp > ./lite_cnacc_data.tmp && awk 'NR == FNR { tmp[$0] = 1 } NR > FNR { if ( tmp[$0] != 1 ) print }' ./lite_cnacc_subtracted.tmp ./lite_gfwlist_subtracted.tmp > ./lite_gfwlist_data.tmp && cat ./cnacc_data.tmp ./lite_cnacc_data.tmp | sort | uniq | awk "{ print $2 }"))
    gfwlist_data=($(cat ./gfwlist_data.tmp ./lite_gfwlist_data.tmp | sort | uniq | awk "{ print $2 }"))
    lite_cnacc_data=($(cat ./lite_cnacc_data.tmp | sort | uniq | awk "{ print $2 }"))
    lite_gfwlist_data=($(cat ./lite_gfwlist_data.tmp | sort | uniq | awk "{ print $2 }"))
}
# File Switch
function FileSwitch() {
    if [ "${generate_file}" == "blackwhite" ]; then
        generate_temp="white"
    elif [ "${generate_file}" == "whiteblack" ]; then
        generate_temp="black"
    else
        generate_temp="${generate_file}"
    fi
}
# Generate Default Upstream
function GenerateDefaultUpstream() {
    FileSwitch
    if [ "${generate_temp}" == "black" ]; then
        for domestic_dns_task in "${!domestic_dns[@]}"; do
            echo "${domestic_dns[$domestic_dns_task]}" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
        done
    elif [ "${generate_temp}" == "white" ]; then
        for foreign_dns_task in "${!foreign_dns[@]}"; do
            echo "${foreign_dns[$foreign_dns_task]}" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
        done
    else
        exit 1
    fi
}
# Generate Rules
function GenerateRules() {
    function GenerateRulesHeader() {
        echo -n "[/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
    }
    function GenerateRulesBody() {
        if [ "${generate_mode}" == "full" ] && [ "${generate_file}" == "black" ]; then
            for cnacc_data_task in "${!cnacc_data[@]}"; do
                echo -n "${cnacc_data[$cnacc_data_task]}/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
            done
        elif [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_split" ] && [ "${generate_file}" == "blackwhite" ]; then
            for cnacc_data_task in "${!cnacc_data[@]}"; do
                echo -n "${cnacc_data[$cnacc_data_task]}/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
            done
        elif [ "${generate_mode}" == "full" ] && [ "${generate_file}" == "white" ]; then
            for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
            done
        elif [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_split" ] && [ "${generate_file}" == "whiteblack" ]; then
            for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
            done
        elif [ "${generate_mode}" == "lite" ] && [ "${generate_file}" == "black" ]; then
            for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                echo -n "${lite_cnacc_data[$lite_cnacc_data_task]}/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
            done
        elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_split" ] && [ "${generate_file}" == "blackwhite" ]; then
            for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                echo -n "${lite_cnacc_data[$lite_cnacc_data_task]}/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
            done
        elif [ "${generate_mode}" == "lite" ] && [ "${generate_file}" == "white" ]; then
            for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                echo -n "${lite_gfwlist_data[$lite_gfwlist_data_task]}/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
            done
        elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_split" ] && [ "${generate_file}" == "whiteblack" ]; then
            for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                echo -n "${lite_gfwlist_data[$lite_gfwlist_data_task]}/" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
            done
        else
            exit 1
        fi
    }
    function GenerateRulesFooter() {
        if [ "${dns_mode}" == "default" ]; then
            echo -e "]#" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
        elif [ "${dns_mode}" == "domestic" ]; then
            echo -e "]${domestic_dns[domestic_dns_task]}" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
        elif [ "${dns_mode}" == "foreign" ]; then
            echo -e "]${foreign_dns[foreign_dns_task]}" >> ../gfwlist2agh_${generate_temp}list_${generate_mode}.txt
        else
            exit 1
        fi
    }
    function GenerateRulesProcess() {
        FileSwitch
        GenerateRulesHeader
        GenerateRulesBody
        GenerateRulesFooter
    }
    if [ "${dns_mode}" == "default" ]; then
        GenerateRulesProcess
    elif [ "${dns_mode}" == "domestic" ]; then
        for domestic_dns_task in "${!domestic_dns[@]}"; do
            GenerateRulesProcess
        done
    elif [ "${dns_mode}" == "foreign" ]; then
        for foreign_dns_task in "${!foreign_dns[@]}"; do
            GenerateRulesProcess
        done
    else
        exit 1
    fi
}
# Output Data
function OutputData() {
    domestic_dns=(
        "https://doh.pub:443/dns-query"
        "tls://dns.alidns.com:853"
    )
    foreign_dns=(
        "https://doh.opendns.com:443/dns-query"
        "tls://dns.google:853"
    )
    for (( generate_task = 0; generate_task < 3; generate_task++ )); do
        case ${generate_task} in
            0)
            generate_file="black" && generate_mode="full" && GenerateDefaultUpstream
            generate_file="black" && generate_mode="full_split" && GenerateDefaultUpstream
            generate_file="black" && generate_mode="lite" && GenerateDefaultUpstream
            generate_file="black" && generate_mode="lite_split" && GenerateDefaultUpstream
            generate_file="white" && generate_mode="full" && GenerateDefaultUpstream
            generate_file="white" && generate_mode="full_split" && GenerateDefaultUpstream
            generate_file="white" && generate_mode="lite" && GenerateDefaultUpstream
            generate_file="white" && generate_mode="lite_split" && GenerateDefaultUpstream
            ;;
            1)
            dns_mode="default" && generate_file="black" && generate_mode="full" && GenerateRules
            dns_mode="default" && generate_file="black" && generate_mode="lite" && GenerateRules
            dns_mode="default" && generate_file="white" && generate_mode="full" && GenerateRules
            dns_mode="default" && generate_file="white" && generate_mode="lite" && GenerateRules
            ;;
            2)
            dns_mode="domestic" && generate_file="blackwhite" && generate_mode="full" && GenerateRules
            dns_mode="domestic" && generate_file="blackwhite" && generate_mode="full_split" && GenerateRules
            dns_mode="domestic" && generate_file="blackwhite" && generate_mode="lite" && GenerateRules
            dns_mode="domestic" && generate_file="blackwhite" && generate_mode="lite_split" && GenerateRules
            dns_mode="foreign" && generate_file="whiteblack" && generate_mode="full" && GenerateRules
            dns_mode="foreign" && generate_file="whiteblack" && generate_mode="full_split" && GenerateRules
            dns_mode="foreign" && generate_file="whiteblack" && generate_mode="lite" && GenerateRules
            dns_mode="foreign" && generate_file="whiteblack" && generate_mode="lite_split" && GenerateRules
            ;;
        esac
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
