#!/usr/bin/env python3

## How to get and use?
# git clone "https://github.com/hezhijie0327/GFWList2AGH.git" && python3 ./GFWList2AGH/build.py

import base64
import re
import shutil
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
DIST_DIR = ROOT / "dist"

CNACC_DOMAIN = (
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/apple-cn.txt",
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt",
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/google-cn.txt",
    "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/China/China_Domain.list",
)
CNACC_TRUSTED = (
    "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf",
    "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf",
    "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf",
)
GFWLIST_BASE64 = (
    "https://raw.githubusercontent.com/Loukky/gfwlist-by-loukky/master/gfwlist.txt",
    "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt",
    "https://raw.githubusercontent.com/poctopus/gfwlist-plus/master/gfwlist-plus.txt",
)
GFWLIST_DOMAIN = (
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt",
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt",
    "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt",
    "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Global/Global_Domain.list",
    "https://raw.githubusercontent.com/pexcn/gfwlist-extras/master/gfwlist-extras.txt",
)
GFWLIST2AGH_MODIFY = (
    "https://raw.githubusercontent.com/hezhijie0327/GFWList2AGH/main/data/data_modify.txt",
)

DOMAIN_REGEX = re.compile(
    r"^(([a-z])|([a-z]{2})|([a-z][0-9])|([0-9][a-z])|([a-z0-9][-\.a-z0-9]{1,61}[a-z0-9]))"
    r"\.([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$"
)
LITE_DOMAIN_REGEX = re.compile(r"^([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$")

# Custom rule markers in data/data_modify.txt: @ add, ! remove, * exclude,
# % China list only, & GFW list only.
MODIFY_MARKERS = {
    "cnacc_addition": ("(@%@)", "(@%!)", "(!&@)", "(@@@)"),
    "cnacc_subtraction": ("(!%!)", "(@&!)", "(!%@)", "(!!!)"),
    "cnacc_exclusion": ("(*%*)", "(***)"),
    "cnacc_keyword": ("(!%*)", "(!**)"),
    "gfwlist_addition": ("(@&@)", "(@&!)", "(!%@)", "(@@@)"),
    "gfwlist_subtraction": ("(!&!)", "(@%!)", "(!&@)", "(!!!)"),
    "gfwlist_exclusion": ("(*&*)", "(***)"),
    "gfwlist_keyword": ("(!&*)", "(!**)"),
}
MARKER_CHARS = str.maketrans("", "", "!%&()*@")


## Function
# Download one URL, return decoded text (empty string on failure, like curl -s)
def download(url):
    try:
        request = Request(url, headers={"User-Agent": "curl/8"})
        with urlopen(request, timeout=15) as response:
            return response.read().decode("utf-8", errors="replace")
    except OSError:
        return ""


# Fetch all URLs in parallel and concatenate (raw append, like curl >> file)
def fetch(urls):
    with ThreadPoolExecutor(max_workers=16) as pool:
        return "".join(pool.map(download, urls))


# Decode base64 tolerantly: keep the decodable prefix on malformed input,
# matching the behaviour of base64 -d in the original pipeline
def decode_base64(text):
    cleaned = re.sub(r"[^A-Za-z0-9+/=]", "", text)
    try:
        return base64.b64decode(cleaned, validate=True)
    except ValueError:
        return base64.b64decode(cleaned[: len(cleaned) // 4 * 4])


# Get Data
def get_data():
    cnacc_domain = fetch(CNACC_DOMAIN)
    cnacc_trusted = fetch(CNACC_TRUSTED)
    gfwlist_domain = fetch(GFWLIST_DOMAIN)
    modify = fetch(GFWLIST2AGH_MODIFY)
    # Mirror the sed/base64 preprocessing of the original pipeline
    cnacc_domain = re.sub(r"^\.", "", cnacc_domain, flags=re.MULTILINE)
    gfwlist_domain = re.sub(r"^\.", "", gfwlist_domain, flags=re.MULTILINE)
    with ThreadPoolExecutor(max_workers=16) as pool:
        parts = list(pool.map(download, GFWLIST_BASE64))
    gfwlist_base64 = "".join(
        decode_base64(part).decode("utf-8", errors="replace") for part in parts if part
    )
    return cnacc_domain, cnacc_trusted, gfwlist_base64, gfwlist_domain, modify


# Extract sorted unique domains matching regex from text
# (split on \n only: a trailing \r stays part of the line, like grep sees it)
def domains(text, regex=DOMAIN_REGEX):
    return sorted({line for line in text.lower().split("\n") if regex.fullmatch(line)})


# Last two labels of a domain (rev | cut -d "." -f 1,2 | rev)
def lite(domain):
    return ".".join(domain.split(".")[-2:])


# Parse data_modify.txt into rule sets
def parse_modify(text):
    rules = {name: set() for name in MODIFY_MARKERS}
    for line in text.split("\n"):
        if "#" in line:
            continue
        for name, markers in MODIFY_MARKERS.items():
            if any(marker in line for marker in markers):
                domain = line.translate(MARKER_CHARS)
                if DOMAIN_REGEX.fullmatch(domain):
                    rules[name].add(domain)
    return rules


# Build the grep -Ev exclusion pattern; an empty set matches everything,
# exactly like the original "(\.()$)|(^()$)|()" behaviour
def exclusion_pattern(exclusion, keyword):
    excl = "|".join(sorted(exclusion))
    kw = "|".join(sorted(keyword))
    return re.compile(r"(\.(" + excl + r")$)|(^" + excl + r"$)|(" + kw + r")")


# Analyse Data
def analyse_data(cnacc_domain, cnacc_trusted, gfwlist_base64, gfwlist_domain, modify):
    rules = parse_modify(modify)
    lite_rules = {
        name: {domain for domain in rules[name] if LITE_DOMAIN_REGEX.fullmatch(domain)}
        for name in ("cnacc_addition", "gfwlist_addition", "cnacc_exclusion", "gfwlist_exclusion",
                     "cnacc_keyword", "gfwlist_keyword")
    }

    cnacc_trust = domains(re.sub(r"/114\.114\.114\.114|server=/", "", cnacc_trusted))
    lite_cnacc_trust = sorted(domain for domain in cnacc_trust if LITE_DOMAIN_REGEX.fullmatch(domain))
    cnacc_checklist = domains(re.sub(r"domain:|full:", "", cnacc_domain))
    gfwlist_checklist = domains(re.sub(r"domain:|full:|https?://", "", gfwlist_base64 + "\n" + gfwlist_domain).replace("|", ""))
    lite_cnacc_checklist = sorted({lite(domain) for domain in cnacc_checklist})
    lite_gfwlist_checklist = sorted({lite(domain) for domain in gfwlist_checklist})

    cnacc_set, gfwlist_set = set(cnacc_checklist), set(gfwlist_checklist)
    trust_set = set(cnacc_trust)
    gfwlist_raw = gfwlist_set - cnacc_set
    cnacc_raw = {
        domain for domain in cnacc_set - gfwlist_set
        if not exclusion_pattern(rules["cnacc_exclusion"], rules["cnacc_keyword"]).search(domain)
    }
    lite_gfwlist_raw = set(lite_gfwlist_checklist) - set(lite_cnacc_checklist)
    lite_cnacc_raw = {
        domain for domain in set(lite_cnacc_checklist) - set(lite_gfwlist_checklist)
        if not exclusion_pattern(lite_rules["cnacc_exclusion"], lite_rules["cnacc_keyword"]).search(domain)
    }
    gfwlist_raw_new = {
        domain for domain in gfwlist_raw - trust_set
        if not exclusion_pattern(rules["gfwlist_exclusion"], rules["gfwlist_keyword"]).search(domain)
    }
    lite_gfwlist_raw_new = {
        domain for domain in lite_gfwlist_raw - trust_set
        if not exclusion_pattern(lite_rules["gfwlist_exclusion"], lite_rules["gfwlist_keyword"]).search(domain)
    }

    cnacc_added = (cnacc_raw | lite_cnacc_raw | rules["cnacc_addition"] | lite_rules["cnacc_addition"]
                   | trust_set | set(lite_cnacc_trust))
    gfwlist_added = gfwlist_raw_new | lite_gfwlist_raw_new | rules["gfwlist_addition"] | lite_rules["gfwlist_addition"]
    lite_cnacc_added = lite_cnacc_raw | lite_rules["cnacc_addition"] | set(lite_cnacc_trust)
    lite_gfwlist_added = lite_gfwlist_raw_new | lite_rules["gfwlist_addition"]

    cnacc_data = sorted((cnacc_added | lite_cnacc_added) - rules["cnacc_subtraction"])
    gfwlist_data = sorted((gfwlist_added | lite_gfwlist_added) - rules["gfwlist_subtraction"])
    lite_cnacc_data = sorted(lite_cnacc_added - rules["cnacc_subtraction"])
    lite_gfwlist_data = sorted(lite_gfwlist_added - rules["gfwlist_subtraction"])
    return cnacc_data, gfwlist_data, lite_cnacc_data, lite_gfwlist_data


# DNS upstreams per software (commented-out alternatives kept for reference)
DNS_UPSTREAM = {
    "adguardhome": {
        "domestic": (
            # "https://dns.alidns.com:443/dns-query"
            # "https://dns.ipv6dns.com:443/dns-query"
            # "https://doh.360.cn:443/dns-query"
            "https://doh.pub:443/dns-query",
            "tls://dns.alidns.com:853",
            # "tls://dns.ipv6dns.com:853"
            # "tls://dot.360.cn:853"
            # "tls://dot.pub:853"
        ),
        "foreign": (
            # "https://dns.google:443/dns-query"
            "https://dns.opendns.com:443/dns-query",
            # "https://dns11.quad9.net:443/dns-query"
            # "https://dns64.dns.google:443/dns-query"
            "tls://dns.google:853",
            # "tls://dns.opendns.com:853"
            # "tls://dns11.quad9.net:853"
            # "tls://dns64.dns.google:853"
        ),
    },
    "bind9": {"domestic": ("223.5.5.5 port 53",), "foreign": ("8.8.8.8 port 53",)},
    "dnsmasq": {"domestic": ("223.5.5.5#53",), "foreign": ("8.8.8.8#53",)},
    "unbound": {"domestic": ("223.5.5.5@853#dns.alidns.com",), "foreign": ("8.8.8.8@853#dns.google",)},
}


# Generate Rules
def generate_rules(software_name, generate_file, generate_mode, data, dns_mode="default", groups=None):
    cnacc_data, gfwlist_data, lite_cnacc_data, lite_gfwlist_data = data
    if generate_file in ("black", "whiteblack"):
        list_name = "black"
    elif generate_file in ("white", "blackwhite"):
        list_name = "white"
    else:
        list_name = "debug"
    extension = "txt" if software_name in ("adguardhome", "domain") else "conf"
    out_dir = DIST_DIR / software_name
    out_dir.mkdir(parents=True, exist_ok=True)
    file_path = out_dir / f"{list_name}list_{generate_mode}.{extension}"

    if generate_mode in ("full", "full_combine"):
        black_data, white_data = cnacc_data, gfwlist_data
    else:
        black_data, white_data = lite_cnacc_data, lite_gfwlist_data
    # AdGuard Home routes the China list into "black" files and vice versa
    if software_name == "adguardhome":
        body_data = black_data if generate_file in ("black", "blackwhite") else white_data
    else:
        body_data = gfwlist_data if generate_file == "black" else cnacc_data
        if generate_mode in ("lite", "lite_combine"):
            body_data = lite_gfwlist_data if generate_file == "black" else lite_cnacc_data

    lines = []
    if software_name == "adguardhome":
        upstream = DNS_UPSTREAM[software_name]
        if generate_mode in ("full", "lite"):
            if generate_file == "blackwhite":
                lines.extend(upstream["foreign"])
            elif generate_file == "whiteblack":
                lines.extend(upstream["domestic"])
        else:
            if generate_file == "black":
                lines.extend(upstream["domestic"])
            elif generate_file == "white":
                lines.extend(upstream["foreign"])
        block = "[/" + "".join(f"{domain}/" for domain in body_data)
        if dns_mode == "default":
            lines.append(block + "]#")
        else:
            lines.append(block + "]" + " ".join(upstream[dns_mode]))
    elif software_name == "bind9":
        dns = DNS_UPSTREAM["bind9"]["foreign" if generate_file == "black" else "domestic"]
        forwarders = "".join(f"{server}; " for server in dns)
        lines = [f'zone "{domain}." {{type forward; forwarders {{ {forwarders}}}; }};' for domain in body_data]
    elif software_name == "dnsmasq":
        dns = DNS_UPSTREAM["dnsmasq"]["foreign" if generate_file == "black" else "domestic"]
        lines = [f"server=/{domain}/{server}" for domain in body_data for server in dns]
    elif software_name == "domain":
        lines = list(body_data)
    elif software_name == "smartdns":
        groups = groups or {}
        group = groups.get("foreign_group", "foreign") if generate_file == "black" else groups.get("domestic_group", "domestic")
        lines = [f"nameserver /{domain}/{group}" for domain in body_data]
    elif software_name == "unbound":
        dns = DNS_UPSTREAM["unbound"][dns_mode]
        footer = [f'    forward-addr: "{server}"' for server in dns]
        footer += [
            '    forward-first: "yes"',
            '    forward-no-cache: "yes"',
            '    forward-ssl-upstream: "yes"',
            '    forward-tls-upstream: "yes"',
        ]
        lines = []
        for domain in body_data:
            lines.append("forward-zone:")
            lines.append(f'    name: "{domain}."')
            lines.extend(footer)
    else:
        sys.exit(1)

    with open(file_path, "a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


# Output Data
def output_data(data):
    # Start from an empty dist so appended blocks never pile up across runs
    if DIST_DIR.exists():
        shutil.rmtree(DIST_DIR)
    for software_name in ("adguardhome",):
        for generate_file, generate_mode, dns_mode in (
            ("black", "full_combine", "default"),
            ("black", "lite_combine", "default"),
            ("white", "full_combine", "default"),
            ("white", "lite_combine", "default"),
            ("blackwhite", "full_combine", "domestic"),
            ("blackwhite", "lite_combine", "domestic"),
            ("whiteblack", "full_combine", "foreign"),
            ("whiteblack", "lite_combine", "foreign"),
            ("blackwhite", "full", "domestic"),
            ("blackwhite", "lite", "domestic"),
            ("whiteblack", "full", "foreign"),
            ("whiteblack", "lite", "foreign"),
        ):
            generate_rules(software_name, generate_file, generate_mode, data, dns_mode)
    for software_name in ("bind9", "dnsmasq", "domain"):
        for generate_file in ("black", "white"):
            for generate_mode in ("full", "lite"):
                generate_rules(software_name, generate_file, generate_mode, data)
    for generate_file in ("black", "white"):
        for generate_mode in ("full", "lite"):
            groups = {"foreign_group": "foreign"} if generate_file == "black" else {"domestic_group": "domestic"}
            generate_rules("smartdns", generate_file, generate_mode, data, groups=groups)
    for generate_file, dns_mode in (("black", "foreign"), ("white", "domestic")):
        for generate_mode in ("full", "lite"):
            generate_rules("unbound", generate_file, generate_mode, data, dns_mode)


## Process
def main():
    data = analyse_data(*get_data())
    output_data(data)


if __name__ == "__main__":
    main()
