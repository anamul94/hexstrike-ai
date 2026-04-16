FROM python:3.12-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    GOPATH=/opt/go \
    PATH=/opt/go/bin:/usr/local/go/bin:/home/appuser/go/bin:${PATH} \
    HEXSTRIKE_HOST=0.0.0.0 \
    HEXSTRIKE_PORT=8888

WORKDIR /app

ARG INSTALL_BASE_TOOLS=true
ARG INSTALL_FULL_TOOLS=true

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    chromium \
    chromium-driver \
    curl \
    dnsutils \
    file \
    git \
    golang-go \
    httpie \
    iproute2 \
    jq \
    libimage-exiftool-perl \
    libpcap-dev \
    netcat-traditional \
    net-tools \
    npm \
    openssh-client \
    perl \
    pkg-config \
    ruby-full \
    ruby-dev \
    sqlite3 \
    tcpdump \
    tshark \
    unzip \
    vim-common \
    wget \
    whois \
    zip \
    && package_has_candidate() { \
         local pkg="$1"; \
         local candidate; \
         candidate="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2}')"; \
         [ -n "$candidate" ] && [ "$candidate" != "(none)" ]; \
       } \
    && if [ "${INSTALL_BASE_TOOLS}" = "true" ]; then \
        packages=( \
          aircrack-ng amass arp-scan binwalk bulk-extractor checksec dirb dnsenum \
          enum4linux enum4linux-ng ffuf fierce feroxbuster foremost \
          gdb gobuster hashcat hydra john masscan nbtscan nikto nmap \
          ophcrack patator radare2 responder scalpel sleuthkit smbclient smbmap \
          sqlmap steghide testdisk theharvester traceroute wafw00f \
          wireshark-common wfuzz xxd zaproxy \
        ); \
        install_list=(); \
        for pkg in "${packages[@]}"; do \
          if package_has_candidate "$pkg"; then \
            install_list+=("$pkg"); \
          else \
            echo "Skipping unavailable apt package: $pkg"; \
          fi; \
        done; \
        if [ "${#install_list[@]}" -gt 0 ]; then \
          apt-get install -y --no-install-recommends "${install_list[@]}"; \
        fi; \
      fi \
    && if [ "${INSTALL_FULL_TOOLS}" = "true" ]; then \
        full_packages=( \
          autopsy checkov default-jre-headless dnsrecon exploitdb ghidra \
          hashid kubectl ldap-utils liblzma-dev mariadb-client metasploit-framework \
          proxychains4 redis-tools rsync seclists swig telnet tnscmd10g tor torsocks \
        ); \
        full_install_list=(); \
        for pkg in "${full_packages[@]}"; do \
          if package_has_candidate "$pkg"; then \
            full_install_list+=("$pkg"); \
          else \
            echo "Skipping unavailable apt package: $pkg"; \
          fi; \
        done; \
        if [ "${#full_install_list[@]}" -gt 0 ]; then \
          apt-get install -y --no-install-recommends "${full_install_list[@]}"; \
        fi; \
      fi \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

RUN pip install --upgrade pip \
    && pip install -r requirements.txt \
    && pip_package_exists() { \
         local pkg="$1"; \
         python -m pip index versions "$pkg" >/dev/null 2>&1; \
       } \
    && pip_install_if_available() { \
         local pkg="$1"; \
         if pip_package_exists "$pkg"; then \
           python -m pip install "$pkg"; \
         else \
           echo "Skipping unavailable pip package: $pkg"; \
         fi; \
       } \
    && if [ "${INSTALL_BASE_TOOLS}" = "true" ]; then \
         for pkg in arjun dirsearch paramspider sherlock-project wafw00f; do \
           pip_install_if_available "$pkg"; \
         done; \
       fi \
    && if [ "${INSTALL_FULL_TOOLS}" = "true" ]; then \
         pip_install_if_available volatility3; \
       fi \
    && gem install --no-document wpscan \
    && mkdir -p /opt/go/bin \
    && if [ "${INSTALL_BASE_TOOLS}" = "true" ]; then \
         GOBIN=/opt/go/bin go install github.com/projectdiscovery/httpx/cmd/httpx@latest \
         && GOBIN=/opt/go/bin go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest \
         && GOBIN=/opt/go/bin go install github.com/projectdiscovery/katana/cmd/katana@latest \
         && GOBIN=/opt/go/bin go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest \
         && GOBIN=/opt/go/bin go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest \
         && GOBIN=/opt/go/bin go install github.com/projectdiscovery/notify/cmd/notify@latest \
         && GOBIN=/opt/go/bin go install github.com/lc/gau/v2/cmd/gau@latest \
         && GOBIN=/opt/go/bin go install github.com/tomnomnom/qsreplace@latest \
         && GOBIN=/opt/go/bin go install github.com/tomnomnom/waybackurls@latest \
         && GOBIN=/opt/go/bin go install github.com/tomnomnom/anew@latest \
         && GOBIN=/opt/go/bin go install github.com/tomnomnom/assetfinder@latest \
         && GOBIN=/opt/go/bin go install github.com/tomnomnom/httprobe@latest \
         && GOBIN=/opt/go/bin go install github.com/hahwul/dalfox/v2@latest \
         && GOBIN=/opt/go/bin go install github.com/hakluke/hakrawler@latest; \
       fi

COPY hexstrike_server.py hexstrike_mcp.py hexstrike-ai-mcp.json README.md LICENSE ./
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && useradd --create-home --shell /bin/bash appuser \
    && mkdir -p /app/data \
    && mkdir -p /opt/go/bin /opt/go/pkg /opt/go/src \
    && mkdir -p /usr/share/wordlists/dirb /usr/share/wordlists/dirbuster /usr/share/wordlists/dirsearch \
    && if [ ! -f /usr/share/wordlists/dirb/common.txt ]; then \
         printf '%s\n' \
           admin \
           administrator \
           api \
           app \
           assets \
           auth \
           backup \
           backups \
           config \
           console \
           dashboard \
           data \
           db \
           debug \
           dev \
           downloads \
           files \
           images \
           include \
           index \
           js \
           lib \
           login \
           logs \
           media \
           old \
           panel \
           private \
           public \
           register \
           robots.txt \
           server-status \
           static \
           staging \
           test \
           tmp \
           uploads \
           user \
           users \
           v1 \
           v2 > /usr/share/wordlists/dirb/common.txt; \
       fi \
    && if [ ! -f /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt ]; then \
         cp /usr/share/wordlists/dirb/common.txt /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt; \
       fi \
    && if [ ! -f /usr/share/wordlists/dirsearch/common.txt ]; then \
         cp /usr/share/wordlists/dirb/common.txt /usr/share/wordlists/dirsearch/common.txt; \
       fi \
    && chown -R appuser:appuser /app /opt/go

USER appuser

EXPOSE 8888

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl --fail http://127.0.0.1:${HEXSTRIKE_PORT}/health || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["server"]
