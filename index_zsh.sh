#!/bin/zsh

# ASDF Auto Install Script - Optimized for Zsh
# Tự động cài đặt các plugin và phiên bản mới nhất của các ngôn ngữ lập trình
# Tối ưu hóa cho zsh với performance và user experience tốt hơn

# Bật zsh options cho script
setopt EXTENDED_GLOB
setopt NULL_GLOB
setopt PIPE_FAIL
setopt ERR_EXIT
setopt NO_UNSET

# Màu sắc cho output (tối ưu hóa cho zsh)
typeset -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [PURPLE]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [WHITE]='\033[1;37m'
    [NC]='\033[0m'
)

# Các biến global
typeset -A plugins
typeset -a manual_version_plugins
typeset -A recommended_versions
typeset -a failed_plugins
typeset -a failed_installs
typeset CONFIG_FILE="./plugins.json"
typeset ASDF_DIR="$HOME/.asdf"
typeset SHELL_CONFIG="$HOME/.zshrc"
typeset TEMP_DIR=""

# Hàm cleanup cho script
cleanup() {
    local exit_code=$?
    [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
    exit $exit_code
}

# Trap cleanup
trap cleanup EXIT INT TERM

# Hàm in thông báo với màu (tối ưu hóa cho zsh)
print_message() {
    local type="$1"
    local message="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$type" in
        "INFO")
            echo -e "${COLORS[BLUE]}[INFO]${COLORS[NC]} ${COLORS[WHITE]}[$timestamp]${COLORS[NC]} $message"
            ;;
        "SUCCESS")
            echo -e "${COLORS[GREEN]}[SUCCESS]${COLORS[NC]} ${COLORS[WHITE]}[$timestamp]${COLORS[NC]} $message"
            ;;
        "WARNING")
            echo -e "${COLORS[YELLOW]}[WARNING]${COLORS[NC]} ${COLORS[WHITE]}[$timestamp]${COLORS[NC]} $message"
            ;;
        "ERROR")
            echo -e "${COLORS[RED]}[ERROR]${COLORS[NC]} ${COLORS[WHITE]}[$timestamp]${COLORS[NC]} $message"
            ;;
        "STEP")
            echo -e "${COLORS[PURPLE]}[STEP]${COLORS[NC]} ${COLORS[WHITE]}[$timestamp]${COLORS[NC]} $message"
            ;;
    esac
}

# Wrapper functions cho các loại message
print_info() { print_message "INFO" "$1"; }
print_success() { print_message "SUCCESS" "$1"; }
print_warning() { print_message "WARNING" "$1"; }
print_error() { print_message "ERROR" "$1"; }
print_step() { print_message "STEP" "$1"; }

# Hàm kiểm tra command tồn tại
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Hàm kiểm tra file tồn tại với validation
file_exists() {
    [[ -f "$1" && -r "$1" ]]
}

# Hàm kiểm tra directory tồn tại
dir_exists() {
    [[ -d "$1" && -r "$1" ]]
}

# Hàm tạo backup của file config
backup_config() {
    local config_file="$1"
    local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if file_exists "$config_file"; then
        cp "$config_file" "$backup_file"
        print_info "Đã tạo backup: $backup_file"
    fi
}

# Hàm thêm cấu hình vào shell config với kiểm tra duplicate
add_config_section() {
    local config_content="$1"
    local section_marker="$2"
    
    backup_config "$SHELL_CONFIG"
    
    # Kiểm tra xem section đã tồn tại chưa
    if grep -q "$section_marker" "$SHELL_CONFIG" 2>/dev/null; then
        print_warning "Section '$section_marker' đã tồn tại trong .zshrc"
        return 0
    fi
    
    # Thêm section mới
    echo "$config_content" >> "$SHELL_CONFIG"
    print_success "Đã thêm section '$section_marker' vào .zshrc"
}

# Hàm reload shell config
reload_shell_config() {
    if file_exists "$SHELL_CONFIG"; then
        source "$SHELL_CONFIG"
        print_info "Đã reload shell config"
    fi
}

# Hàm cài đặt các gói cần thiết với error handling tốt hơn
install_required_packages() {
    print_step "Cài đặt các gói cần thiết..."
    
    local packages=("jq" "gnupg" "curl" "wget" "unzip" "build-essential" "autoconf" "libncurses5-dev" "libssl-dev" "ca-certificates" "liblzma-dev" "python3-tk")
    local installed_packages=()
    
    # Cleanup và update
    print_info "Dọn dẹp cache và cập nhật hệ thống..."
    {
        sudo apt clean
        sudo apt autoclean
        sudo rm -rf /var/lib/apt/lists/*
        sudo apt update -y --fix-missing
        sudo apt --fix-broken install -y
    } || {
        print_error "Không thể cập nhật hệ thống"
        return 1
    }
    
    # Cài đặt từng gói với progress tracking
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            print_info "$package đã được cài đặt"
            installed_packages+=("$package")
            continue
        fi
        
        print_info "Cài đặt $package..."
        if sudo apt install -y --fix-missing --fix-broken "$package"; then
            print_success "Đã cài đặt $package"
            installed_packages+=("$package")
        else
            print_warning "Không thể cài đặt $package, thử với --no-install-recommends..."
            if sudo apt install -y --fix-missing --fix-broken --no-install-recommends "$package"; then
                print_success "Đã cài đặt $package (không có gói khuyến nghị)"
                installed_packages+=("$package")
            else
                print_error "Không thể cài đặt $package"
            fi
        fi
    done
    
    # Kiểm tra kết quả
    local failed_count=$((${#packages[@]} - ${#installed_packages[@]}))
    if [[ $failed_count -gt 0 ]]; then
        print_warning "$failed_count gói không thể cài đặt"
    else
        print_success "Đã cài đặt tất cả gói cần thiết"
    fi
    
    # Refresh PATH
    hash -r
    rehash
}

# Hàm load config từ JSON với validation
load_config() {
    print_step "Load cấu hình từ JSON..."
    
    if ! file_exists "$CONFIG_FILE"; then
        print_error "Không tìm thấy file cấu hình $CONFIG_FILE"
        return 1
    fi
    
    # Validate JSON format
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        print_error "File cấu hình JSON không hợp lệ"
        return 1
    fi
    
    # Clear arrays
    plugins=()
    manual_version_plugins=()
    recommended_versions=()
    
    # Load plugins với error handling
    local plugin_data
    plugin_data=$(jq -r '.plugins | to_entries[] | "\(.key)=\(.value)"' "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -n "$plugin_data" ]]; then
        while IFS='=' read -r key value; do
            plugins["$key"]="$value"
        done <<< "$plugin_data"
        print_info "Đã load ${#plugins[@]} plugins"
    fi
    
    # Load manual version plugins
    local manual_data
    manual_data=$(jq -r '.special_handling.manual_version[]?' "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -n "$manual_data" ]]; then
        while IFS= read -r plugin; do
            [[ -n "$plugin" ]] && manual_version_plugins+=("$plugin")
        done <<< "$manual_data"
        print_info "Đã load ${#manual_version_plugins[@]} manual version plugins"
    fi
    
    # Load recommended versions
    local recommended_data
    recommended_data=$(jq -r '.special_handling.recommended_versions | to_entries[]? | "\(.key)=\(.value)"' "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -n "$recommended_data" ]]; then
        while IFS='=' read -r key value; do
            recommended_versions["$key"]="$value"
        done <<< "$recommended_data"
        print_info "Đã load ${#recommended_versions[@]} recommended versions"
    fi
    
    print_success "Đã load cấu hình thành công"
}

# Hàm cấu hình ASDF
configure_asdf_shell() {
    print_step "Cấu hình ASDF cho zsh..."
    
    local asdf_config="
# ASDF Configuration
export ASDF_DIR=\"$ASDF_DIR\"
export PATH=\"\$ASDF_DIR/bin:\$ASDF_DIR/shims:\$PATH\"

# ASDF completions for zsh
if [[ -f \$ASDF_DIR/completions/asdf.zsh ]]; then
    source \$ASDF_DIR/completions/asdf.zsh
fi

# ASDF zsh integration
if [[ -f \$ASDF_DIR/asdf.sh ]]; then
    source \$ASDF_DIR/asdf.sh
fi"
    
    add_config_section "$asdf_config" "ASDF Configuration"
    reload_shell_config
}

# Hàm kiểm tra và cài đặt asdf
install_asdf() {
    print_step "Kiểm tra và cài đặt asdf..."
    
    if command_exists asdf; then
        print_success "asdf đã được cài đặt"
        return 0
    fi
    
    # Prompt user for asdf URL
    local asdf_url
    print_info "asdf chưa được cài đặt."
    echo
    read "asdf_url?Nhập link tải asdf (ví dụ: https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz): "
    
    if [[ -z "$asdf_url" ]]; then
        print_error "Link không được để trống"
        return 1
    fi
    
    # Tạo temp directory
    TEMP_DIR=$(mktemp -d)
    local original_dir="$PWD"
    
    {
        cd "$TEMP_DIR"
        
        # Download asdf
        print_info "Đang tải asdf..."
        if curl -fsSL "$asdf_url" -o asdf.tar.gz; then
            print_success "Đã tải asdf"
        else
            print_error "Không thể tải asdf từ $asdf_url"
            return 1
        fi
        
        # Extract
        print_info "Đang giải nén asdf..."
        if tar -xzf asdf.tar.gz; then
            print_success "Đã giải nén asdf"
        else
            print_error "Không thể giải nén asdf"
            return 1
        fi
        
        # Find asdf executable
        local asdf_bin
        asdf_bin=$(find . -name "asdf" -type f -executable | head -1)
        
        if [[ -z "$asdf_bin" ]]; then
            print_error "Không tìm thấy file thực thi asdf"
            return 1
        fi
        
        # Install asdf
        if sudo cp "$asdf_bin" /usr/local/bin/asdf && sudo chmod +x /usr/local/bin/asdf; then
            print_success "Đã cài đặt asdf vào /usr/local/bin"
        else
            print_error "Không thể cài đặt asdf"
            return 1
        fi
        
        cd "$original_dir"
    } || {
        cd "$original_dir"
        return 1
    }
    
    # Configure asdf
    configure_asdf_shell
    
    # Refresh PATH
    hash -r
    rehash
    
    print_success "Đã cài đặt và cấu hình asdf thành công"
}

# Hàm setup certificates
setup_certificates() {
    print_step "Cài đặt chứng chỉ SSL..."
    
    if ! dir_exists "./certs"; then
        print_warning "Thư mục ./certs không tồn tại, bỏ qua bước cài đặt chứng chỉ"
        return 0
    fi
    
    # Copy certificates
    print_info "Đang sao chép chứng chỉ..."
    if sudo cp ./certs/* /usr/local/share/ca-certificates/ && sudo cp ./certs/* /etc/ssl/certs/; then
        print_success "Đã sao chép chứng chỉ"
    else
        print_error "Không thể sao chép chứng chỉ"
        return 1
    fi
    
    # Update certificates
    print_info "Đang cập nhật chứng chỉ..."
    if sudo update-ca-certificates; then
        print_success "Đã cập nhật chứng chỉ"
    else
        print_error "Không thể cập nhật chứng chỉ"
        return 1
    fi
    
    # Configure shell environment
    configure_shell_certificates
}

# Hàm cấu hình biến môi trường chứng chỉ
configure_shell_certificates() {
    local cert_config="
# CERTIFICATE CONFIGURATION
export SSL_CERT_FILE=\"/etc/ssl/certs/ca-certificates.crt\"
export SSL_CERT_DIR=\"/etc/ssl/certs\"
export REQUESTS_CA_BUNDLE=\"/etc/ssl/certs/ca-certificates.crt\"
export CURL_CA_BUNDLE=\"/etc/ssl/certs/ca-certificates.crt\"

# Tool-specific certificate configuration
export BUN_CA_BUNDLE_PATH=\"/etc/ssl/certs/ca-certificates.crt\"
export DENO_CERT=\"/etc/ssl/certs/ca-certificates.crt\"
export NODE_EXTRA_CA_CERTS=\"/etc/ssl/certs/ca-certificates.crt\""
    
    add_config_section "$cert_config" "CERTIFICATE CONFIGURATION"
    reload_shell_config
}

# Hàm cài đặt Docker và Podman
install_docker_podman() {
    print_step "Cài đặt Docker và Podman..."
    
    # Update system
    print_info "Cập nhật hệ thống..."
    if sudo apt update -y --fix-missing && sudo apt upgrade -y --fix-missing; then
        print_success "Đã cập nhật hệ thống"
    else
        print_error "Không thể cập nhật hệ thống"
        return 1
    fi
    
    # Create keyrings directory
    print_info "Tạo thư mục keyrings..."
    if sudo mkdir -p /etc/apt/keyrings && sudo chmod 755 /etc/apt/keyrings; then
        print_success "Đã tạo thư mục keyrings"
    else
        print_error "Không thể tạo thư mục keyrings"
        return 1
    fi
    
    # Add Docker GPG key
    print_info "Thêm Docker GPG key..."
    if ! command_exists gpg; then
        print_error "GPG không khả dụng"
        return 1
    fi
    
    if curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
        print_success "Đã thêm Docker GPG key"
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    else
        print_error "Không thể thêm Docker GPG key"
        return 1
    fi
    
    # Add Docker repository
    print_info "Thêm Docker repository..."
    if echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list; then
        print_success "Đã thêm Docker repository"
    else
        print_error "Không thể thêm Docker repository"
        return 1
    fi
    
    # Update package list
    print_info "Cập nhật danh sách gói..."
    if sudo apt update -y --fix-missing; then
        print_success "Đã cập nhật danh sách gói"
    else
        print_error "Không thể cập nhật danh sách gói"
        return 1
    fi
    
    # Remove conflicting packages
    print_info "Xóa gói xung đột..."
    if dpkg -l | grep -q docker-buildx; then
        sudo apt remove -y docker-buildx || true
    fi
    
    # Fix broken packages
    print_info "Sửa lỗi gói bị hỏng..."
    sudo apt install -f -y --fix-missing --fix-broken
    
    # Install Docker and Podman
    print_info "Cài đặt Docker và Podman..."
    local docker_packages=("podman" "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")
    
    if sudo apt install -y --fix-missing --fix-broken "${docker_packages[@]}"; then
        print_success "Đã cài đặt Docker và Podman"
    else
        print_error "Không thể cài đặt Docker và Podman"
        return 1
    fi
    
    # Add user to docker group
    if sudo usermod -aG docker "$USER"; then
        print_success "Đã thêm user vào docker group"
    fi
}

# Hàm thêm plugin với retry logic
add_plugin() {
    local plugin_name="$1"
    local plugin_url="$2"
    local max_retries=3
    local retry_count=0
    
    print_info "Đang thêm plugin: $plugin_name"
    
    # Kiểm tra plugin đã tồn tại chưa
    if asdf plugin list 2>/dev/null | grep -q "^$plugin_name$"; then
        print_warning "Plugin $plugin_name đã tồn tại, bỏ qua..."
        return 0
    fi
    
    # Thử thêm plugin với retry
    while [[ $retry_count -lt $max_retries ]]; do
        if [[ -n "$plugin_url" ]]; then
            if asdf plugin add "$plugin_name" "$plugin_url" 2>/dev/null; then
                print_success "Đã thêm plugin $plugin_name"
                return 0
            fi
        else
            if asdf plugin add "$plugin_name" 2>/dev/null; then
                print_success "Đã thêm plugin $plugin_name"
                return 0
            fi
        fi
        
        ((retry_count++))
        if [[ $retry_count -lt $max_retries ]]; then
            print_warning "Thử lại lần $retry_count cho plugin $plugin_name..."
            sleep 2
        fi
    done
    
    print_error "Không thể thêm plugin $plugin_name sau $max_retries lần thử"
    return 1
}

# Hàm cài đặt phiên bản với improved user interaction
install_latest() {
    local plugin_name="$1"
    local version=""
    
    print_info "Đang cài đặt $plugin_name..."
    
    # Kiểm tra plugin có cần manual version không
    local needs_manual=false
    for manual_plugin in "${manual_version_plugins[@]}"; do
        if [[ "$plugin_name" == "$manual_plugin" ]]; then
            needs_manual=true
            break
        fi
    done
    
    if [[ "$needs_manual" == true ]]; then
        # Hiển thị available versions
        print_info "Đang lấy danh sách phiên bản cho $plugin_name..."
        local available_versions
        available_versions=$(asdf list all "$plugin_name" 2>/dev/null | tail -10)
        
        if [[ -n "$available_versions" ]]; then
            echo -e "${COLORS[CYAN]}Các phiên bản gần đây:${COLORS[NC]}"
            echo "$available_versions"
        fi
        
        # Prompt for version with recommendation
        local prompt="Nhập phiên bản $plugin_name"
        if [[ -n "${recommended_versions[$plugin_name]}" ]]; then
            prompt="$prompt (khuyến nghị: ${recommended_versions[$plugin_name]})"
        fi
        
        read "version?$prompt: "
        
        if [[ -z "$version" ]]; then
            print_error "Phiên bản không được để trống"
            return 1
        fi
        
        print_info "Đang cài đặt $plugin_name phiên bản $version..."
    else
        # Lấy phiên bản mới nhất
        version=$(asdf latest "$plugin_name" 2>/dev/null)
        if [[ -z "$version" ]]; then
            print_error "Không thể lấy phiên bản mới nhất của $plugin_name"
            return 1
        fi
        print_info "Đang cài đặt $plugin_name phiên bản $version..."
    fi
    
    # Install với timeout
    local install_timeout=600  # 10 minutes
    if timeout "$install_timeout" asdf install "$plugin_name" "$version"; then
        print_success "Đã cài đặt $plugin_name phiên bản $version"
        
        # Set global version
        if asdf global "$plugin_name" "$version"; then
            print_success "Đã đặt $plugin_name $version làm phiên bản global"
        else
            print_warning "Không thể đặt $plugin_name $version làm phiên bản global"
        fi
    else
        print_error "Không thể cài đặt $plugin_name (timeout hoặc lỗi)"
        return 1
    fi
}

# Hàm sửa lỗi Zig plugin
fix_zig_plugin() {
    print_step "Kiểm tra và sửa lỗi Zig plugin..."
    
    # Kiểm tra zig đã được cài đặt thành công chưa
    if asdf list zig 2>/dev/null | grep -q "[0-9]"; then
        print_success "Zig đã được cài đặt thành công"
        return 0
    fi
    
    local zig_utils_path="$ASDF_DIR/plugins/zig/lib/utils.py"
    
    if ! file_exists "$zig_utils_path"; then
        print_warning "Không tìm thấy file $zig_utils_path"
        return 0
    fi
    
    print_info "Đang sửa lỗi Zig plugin..."
    
    # Create improved utils.py
    cat > "$zig_utils_path" << 'EOF'
#!/usr/bin/env python3
# coding: utf-8

import ssl
ssl._create_default_https_context = ssl._create_unverified_context
import os
import random
import platform
import sys
import urllib.request
from urllib.parse import urljoin
from urllib.error import HTTPError
import json
import hashlib
import logging

INDEX_URL = os.getenv("ASDF_ZIG_INDEX_URL", "https://ziglang.org/download/index.json")
HTTP_TIMEOUT = int(os.getenv("ASDF_ZIG_HTTP_TIMEOUT", "30"))
USER_AGENT = "asdf-zig (https://github.com/asdf-community/asdf-zig)"

MIRRORS = [
    "https://pkg.machengine.org/zig",
    "https://zigmirror.hryx.net/zig",
    "https://zig.linus.dev/zig",
    "https://fs.liujiacai.net/zigbuilds",
]

OS_MAPPING = {
    "darwin": "macos",
}

ARCH_MAPPING = {
    "i386": "x86",
    "i686": "x86",
    "amd64": "x86_64",
    "arm64": "aarch64",
}

class HTTPAccessError(Exception):
    def __init__(self, url, code, reason, body):
        super().__init__(f"{url} access failed, code:{code}, reason:{reason}, body:{body}")
        self.url = url
        self.code = code
        self.reason = reason
        self.body = body

def http_get(url, timeout=HTTP_TIMEOUT):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
        return urllib.request.urlopen(req, timeout=timeout)
    except HTTPError as e:
        body = e.read().decode("utf-8")
        raise HTTPAccessError(url, e.code, e.reason, body)

def fetch_index():
    with http_get(INDEX_URL) as response:
        body = response.read().decode("utf-8")
        return json.loads(body)

def all_versions():
    index = fetch_index()
    versions = [k for k in index.keys() if k != "master"]
    versions.sort(key=lambda v: tuple(map(int, v.split("."))))
    return versions

def download_and_check(url, out_file, expected_shasum, total_size):
    logging.info(f"Begin download tarball({total_size}) from {url} to {out_file}...")
    chunk_size = 1024 * 1024  # 1M chunks
    sha256_hash = hashlib.sha256()
    with http_get(url) as response:
        read_size = 0
        with open(out_file, "wb") as f:
            while True:
                chunk = response.read(chunk_size)
                read_size += len(chunk)
                progress_percentage = (read_size / total_size) * 100 if total_size > 0 else 0
                logging.info(f'Downloaded: {read_size}/{total_size} bytes ({progress_percentage:.2f}%)')
                if not chunk:
                    break
                sha256_hash.update(chunk)
                f.write(chunk)

    actual = sha256_hash.hexdigest()
    if actual != expected_shasum:
        raise Exception(f"Shasum not match, expected:{expected_shasum}, actual:{actual}")

def download_tarball(url, out_file, expected_shasum, total_size):
    filename = url.split("/")[-1]
    random.shuffle(MIRRORS)

    for mirror in MIRRORS:
        try:
            mirror = mirror if mirror.endswith('/') else mirror + '/'
            download_and_check(urljoin(mirror, filename), out_file, expected_shasum, total_size)
            return
        except Exception as e:
            logging.error(f"Current mirror failed, try next. err:{e}")

    download_and_check(url, out_file, expected_shasum, total_size)

def download(version, out_file):
    index = fetch_index()
    if version not in index:
        raise Exception(f"There is no such version: {version}")

    links = index[version]
    os_name = platform.system().lower()
    arch = platform.machine().lower()
    os_name = OS_MAPPING.get(os_name, os_name)
    arch = ARCH_MAPPING.get(arch, arch)
    link_key = f"{arch}-{os_name}"
    if link_key not in links:
        raise Exception(f"No tarball link for {link_key} in {version}")

    tarball_url = links[link_key]["tarball"]
    tarball_shasum = links[link_key]["shasum"]
    tarball_size = int(links[link_key]["size"])
    download_tarball(tarball_url, out_file, tarball_shasum, tarball_size)

def main(args):
    command = args[0] if args else "all-versions"
    if command == "all-versions":
        versions = all_versions()
        print(" ".join(versions))
    elif command == "latest-version":
        versions = all_versions()
        print(versions[-1])
    elif command == "download":
        download(args[1], args[2])
    else:
        logging.error(f"Unknown command: {command}")
        sys.exit(1)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(message)s')
    main(sys.argv[1:])
EOF
    
    print_success "Đã sửa lỗi Zig plugin"
}

# Hàm cấu hình các công cụ với chứng chỉ SSL
configure_tools() {
    print_step "Cấu hình các công cụ với chứng chỉ SSL..."
    
    local cert_file="/etc/ssl/certs/ca-certificates.crt"
    
    # Tool configurations
    local -A tool_configs=(
        ["npm"]="npm config set cafile $cert_file && npm config set strict-ssl true"
        ["git"]="git config --global http.sslCAInfo $cert_file && git config --global http.sslVerify true"
        ["cargo"]="cargo config --global http.cainfo $cert_file"
        ["go"]="go env -w GOPROXY=direct"
    )
    
    # Configure tools
    for tool cmd in "${(@kv)tool_configs}"; do
        if command_exists "$tool"; then
            print_info "Cấu hình $tool..."
            eval "$cmd" 2>/dev/null || print_warning "Không thể cấu hình $tool"
        fi
    done
    
    # Create config files
    print_info "Tạo các file cấu hình..."
    
    # Wget config
    echo "ca_certificate = $cert_file" >> ~/.wgetrc
    
    # Pip config
    mkdir -p ~/.config/pip
    cat > ~/.config/pip/pip.conf << EOF
[global]
cert = $cert_file
EOF
    
    # Hex config (Elixir)
    mkdir -p ~/.config/hex
    echo 'unsafe_https: false' > ~/.config/hex/hex.config
    
    print_success "Đã cấu hình tất cả các công cụ"
}

# Hàm hiển thị progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local task="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${COLORS[CYAN]}[%s] %3d%% [%s%s] %s${COLORS[NC]}" \
        "$(date '+%H:%M:%S')" \
        "$percentage" \
        "$(printf '%*s' $filled | tr ' ' '=')" \
        "$(printf '%*s' $empty | tr ' ' '-')" \
        "$task"
}

# Hàm main với improved flow
main() {
    print_step "Bắt đầu cài đặt ASDF và các ngôn ngữ lập trình..."
    echo
    
    # Kiểm tra zsh
    if [[ "$SHELL" != *"zsh"* ]]; then
        print_warning "Script được tối ưu hóa cho zsh, bạn đang sử dụng: $SHELL"
    fi
    
    # Initialize arrays
    failed_plugins=()
    failed_installs=()
    
    # Step 1: Setup certificates
    setup_certificates
    
    # Step 2: Install required packages
    install_required_packages
    
    # Step 3: Load configuration
    load_config
    
    # Step 4: Install Docker and Podman
    install_docker_podman
    
    # Step 5: Install asdf
    install_asdf
    
    # Step 6: Add plugins
    print_step "Thêm các plugin..."
    local plugin_count=0
    local total_plugins=${#plugins[@]}
    
    for plugin in "${(@k)plugins}"; do
        ((plugin_count++))
        show_progress $plugin_count $total_plugins "Thêm plugin $plugin"
        
        if ! add_plugin "$plugin" "${plugins[$plugin]}"; then
            failed_plugins+=("$plugin")
        fi
    done
    
    echo  # New line after progress
    
    # Step 7: Install language versions
    print_step "Cài đặt các phiên bản ngôn ngữ..."
    local install_count=0
    local total_installs=$((total_plugins - ${#failed_plugins[@]}))
    
    for plugin in "${(@k)plugins}"; do
        # Skip failed plugins
        if [[ " ${failed_plugins[*]} " =~ " $plugin " ]]; then
            print_warning "Bỏ qua cài đặt $plugin vì plugin không thể thêm được"
            continue
        fi
        
        ((install_count++))
        show_progress $install_count $total_installs "Cài đặt $plugin"
        
        if ! install_latest "$plugin"; then
            failed_installs+=("$plugin")
        fi
    done
    
    echo  # New line after progress
    
    # Step 8: Fix Zig plugin
    fix_zig_plugin
    
    # Step 9: Configure tools
    configure_tools
    
    # Step 10: Final configuration
    configure_asdf_shell
    
    # Summary
    print_summary
    
    # Reload shell
    print_info "Khởi động lại shell để áp dụng tất cả cấu hình..."
    exec zsh
}

# Hàm hiển thị tóm tắt kết quả
print_summary() {
    echo
    print_step "=== TÓM TẮT KẾT QUẢ ==="
    
    local total_plugins=${#plugins[@]}
    local successful_plugins=$((total_plugins - ${#failed_plugins[@]}))
    local successful_installs=$((successful_plugins - ${#failed_installs[@]}))
    
    echo -e "${COLORS[CYAN]}Tổng số plugins: ${COLORS[WHITE]}$total_plugins${COLORS[NC]}"
    echo -e "${COLORS[GREEN]}Plugins thành công: ${COLORS[WHITE]}$successful_plugins${COLORS[NC]}"
    echo -e "${COLORS[GREEN]}Cài đặt thành công: ${COLORS[WHITE]}$successful_installs${COLORS[NC]}"
    
    if [[ ${#failed_plugins[@]} -gt 0 ]]; then
        echo -e "${COLORS[RED]}Plugins thất bại: ${COLORS[WHITE]}${failed_plugins[*]}${COLORS[NC]}"
    fi
    
    if [[ ${#failed_installs[@]} -gt 0 ]]; then
        echo -e "${COLORS[RED]}Cài đặt thất bại: ${COLORS[WHITE]}${failed_installs[*]}${COLORS[NC]}"
    fi
    
    if [[ ${#failed_plugins[@]} -eq 0 && ${#failed_installs[@]} -eq 0 ]]; then
        print_success "Tất cả plugin và ngôn ngữ đã được cài đặt thành công!"
    fi
    
    echo
    print_info "Các lệnh hữu ích:"
    echo "  asdf list                 - Xem các phiên bản đã cài đặt"
    echo "  asdf current              - Xem các phiên bản hiện tại"
    echo "  asdf plugin list          - Xem danh sách plugins"
    echo "  asdf list all <plugin>    - Xem tất cả phiên bản có sẵn"
    echo "  asdf global <plugin> <version>  - Đặt phiên bản global"
    echo "  asdf local <plugin> <version>   - Đặt phiên bản local"
}

# Chạy script
main "$@"