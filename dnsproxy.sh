#!/bin/bash

# Current Version: 1.0.0

## How to get and use?
# git clone "https://github.com/hezhijie0327/GFWList2AGH.git" && bash ./GFWList2AGH/dnsproxy.sh

## Parameter
while getopts b:c:e:f:h:k:l:m:p:q:r:t GetParameter; do
    case ${GetParameter} in
        b) BOOTSTRAP="${OPTARG}";;
        c) TLSCRT="${OPTARG}";;
        e) ENCRYPT="${OPTARG}";;
        f) FALLBACK="${OPTARG}";;
        h) HTTPSPORT="${OPTARG}";;
        k) TLSKEY="${OPTARG}";;
        l) LISTEN="${OPTARG}";;
        m) MODE="${OPTARG}";;
        p) PORT="${OPTARG}";;
        q) QUICPORT="${OPTARG}";;
        r) RATELIMIT="${OPTARG}";;
        t) TLSPORT="${OPTARG}";;
    esac
done

## Function
# Check Environment
function CheckEnvironment() {
    if [ ! -d "/etc/dnsproxy" ]; then
        mkdir "/etc/dnsproxy"
    fi
    if [ ! -d "/etc/dnsproxy/cert" ]; then
        mkdir "/etc/dnsproxy/cert"
    fi
    if [ ! -d "/etc/dnsproxy/conf" ]; then
        mkdir "/etc/dnsproxy/conf"
    fi
    if [ ! -d "/etc/dnsproxy/work" ]; then
        mkdir "/etc/dnsproxy/work"
    fi
    if [ ! -f "/etc/dnsproxy/conf/runtime.sh" ]; then
        GenerateRuntimeScript && echo "$(($(date '+%s') + 86400))" > "/etc/dnsproxy/work/dnsproxy.exp"
    else
        if [ ! -f "/etc/aria2/work/aria2.exp" ]; then
            echo "$(date '+%s')" > "/etc/dnsproxy/work/dnsproxy.exp"
        fi
        if [ "$(cat '"/etc/dnsproxy/work/dnsproxy.exp"')" -le "$(date '+%s')" ]; then
            GenerateRuntimeScript && echo "$(($(date '+%s') + 86400))" > "/etc/dnsproxy/work/dnsproxy.exp"
        fi
    fi
}
# Get Upstream Data
function GetUpstreamData() {
    upstream_data=($(wget -qO- "https://source.zhijie.online/GFWList2AGH/main/gfwlist2agh_combine.txt" | awk "{ print $2 }"))
}
# Generate Defafult Template
function GenerateDefafultTemplate() {
    echo '#!/bin/bash' > /etc/dnsproxy/conf/runtime.sh
    echo "dnsproxy ${MODE:---all-servers} --cache --edns --refuse-any --verbose" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --listen=${LISTEN:-0.0.0.0} --ratelimit=${RATELIMIT:-500}" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --cache-max-ttl=86400 --cache-min-ttl=10 --cache-size=65536" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --https-port=${HTTPSPORT:-0} --port=${PORT:-53} --quic-port=${QUICPORT:-0} --tls-port=${TLSPORT:-0}" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --bootstrap=${BOOTSTRAP:-223.5.5.5:53} --fallback=${FALLBACK:-223.6.6.6:53}" '\' >> /etc/dnsproxy/conf/runtime.sh
}
# Generate Encrypt Template
function GenerateEncryptTemplate() {
    echo '#!/bin/bash' > /etc/dnsproxy/conf/runtime.sh
    echo "dnsproxy ${MODE:---all-servers} --cache --edns --refuse-any --verbose" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --listen=${LISTEN:-0.0.0.0} --ratelimit=${RATELIMIT:-500}" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --cache-max-ttl=86400 --cache-min-ttl=10 --cache-size=65536" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --https-port=${HTTPSPORT:-443} --port=${PORT:-53} --quic-port=${QUICPORT:-784} --tls-port=${TLSPORT:-853}" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --tls-crt=/etc/dnsproxy/cert/${TLSCRT:-fullchain.pem} --tls-key=/etc/dnsproxy/cert/${TLSKEY:-privkey.pem}" '\' >> /etc/dnsproxy/conf/runtime.sh
    echo "    --bootstrap=${BOOTSTRAP:-223.5.5.5:53} --fallback=${FALLBACK:-223.6.6.6:53}" '\' >> /etc/dnsproxy/conf/runtime.sh
}
# Generate Upstream Config
function GenerateUpstreamConfig() {
    GetUpstreamData
    for upstream_data_task in "${!upstream_data[@]}"; do
        if [ "${upstream_data_task}" == "${#array_name[@]}" ]; then
            echo "    --upstream=${upstream_data[$upstream_data_task]}"
        else
            echo "    --upstream=${upstream_data[$upstream_data_task]}" '\'
        fi
    done
}
# Generate Runtime Script
function GenerateRuntimeScript() {
    if [ "${ENCRYPT:-enable}" == "disable" ]; then
        GenerateDefafultTemplate && GenerateUpstreamConfig
    elif [ "${ENCRYPT:-enable}" == "enable" ]; then
        GenerateEncryptTemplate && GenerateUpstreamConfig
    else
        exit 1
    fi
}

## Process
# Call CheckEnvironment
CheckEnvironment
# Run dnsproxy
bash /etc/dnsproxy/conf/runtime.sh
