#!/usr/bin/env python3
"""
sync_qx_dns.py - 从 QX_AI.list / Finance.list / Private.list 生成 QX_Pro.conf 的海外 DoH 定向解析区块。
保持根域名与子域名分别声明，同一上游的重复父子域名自动合并。
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORKSPACE = ROOT.parent
QX_PRO = WORKSPACE / "QX_Pro.conf"
UPSTREAM = "https://cloudflare-dns.com/dns-query"

BEGIN_MARKER = "# BEGIN GENERATED OVERSEAS DOH"
END_MARKER = "# END GENERATED OVERSEAS DOH"

HEADER_COMMENTS = [
    BEGIN_MARKER,
    "# 来源：QX_AI.list / Finance.list / Private.list 中 AI、Banking 域名及手选主流下的 Intercom / 风控定位域名。",
    "# 仅描述解析器选择；QX 内置 DoH 不保证服从代理规则，须验证当前网络可达性。",
    "# 代理连接通常在节点端解析；不能以此保证解析地理位置与业务出口一致。",
    "# 更新：python3 proxy-conf/scripts/sync_qx_dns.py（从工作区根目录运行）",
]


def load_rules(path: pathlib.Path, allowed_policies: set[str] | None = None):
    hosts = set()
    suffixes = set()
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split(",")]
        if len(parts) < 3:
            continue
        kind, domain, policy = parts[0], parts[1].lower(), parts[2]
        if allowed_policies and policy not in allowed_policies:
            continue
        if kind == "HOST":
            hosts.add(domain)
        elif kind == "HOST-SUFFIX":
            suffixes.add(domain)
    return hosts, suffixes


def is_covered_by_parent(domain: str, suffixes: set[str]) -> bool:
    parts = domain.split(".")
    for i in range(1, len(parts)):
        parent = ".".join(parts[i:])
        if parent in suffixes:
            return True
    return False


def main():
    h1, s1 = load_rules(ROOT / "QX_AI.list", {"AI"})
    h2, s2 = load_rules(ROOT / "Finance.list", {"Banking"})
    h3, s3 = load_rules(ROOT / "Private.list", {"AI", "Banking"})

    # Private.list 中手选主流下的 Intercom 与风控定位域名
    intercom_and_risk = {
        "intercom.com",
        "intercom.io",
        "intercomcdn.com",
        "intercom-chat.com",
        "intercom-sheets.com",
        "fpjs.io",
        "fingerprint.com",
        "maxmind.com",
    }
    raw_hosts = (h1 | h2 | h3 | {"location.microsoft.com"})
    raw_suffixes = (s1 | s2 | s3 | intercom_and_risk)

    # 合并重复父子后缀（如 *.ai 已覆盖所有 .ai 子域，arkoselabs.com 已覆盖子域）
    merged_suffixes = {
        d for d in raw_suffixes if not is_covered_by_parent(d, raw_suffixes)
    }
    merged_hosts = {
        d
        for d in raw_hosts
        if d not in merged_suffixes and not is_covered_by_parent(d, merged_suffixes)
    }

    all_domains = sorted(merged_suffixes | merged_hosts)
    lines = list(HEADER_COMMENTS)
    for d in all_domains:
        lines.append(f"doh-server=/{d}/{UPSTREAM}")
        if d in merged_suffixes:
            lines.append(f"doh-server=/*.{d}/{UPSTREAM}")
    lines.append(END_MARKER)
    block = "\n".join(lines)

    if QX_PRO.exists():
        content = QX_PRO.read_text(encoding="utf-8")
        pattern = re.compile(
            re.escape(BEGIN_MARKER) + r".*?" + re.escape(END_MARKER),
            re.DOTALL,
        )
        if pattern.search(content):
            new_content = pattern.sub(block, content)
            QX_PRO.write_text(new_content, encoding="utf-8")
            print(
                f"Updated {QX_PRO.name}: {len(merged_suffixes)} suffixes, {len(merged_hosts)} exact hosts ({len(lines) - len(HEADER_COMMENTS) - 1} doh-server lines)"
            )
        else:
            print(f"Markers not found in {QX_PRO}")
    else:
        print(f"{QX_PRO} not found")


if __name__ == "__main__":
    main()
