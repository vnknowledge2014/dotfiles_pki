#!/usr/bin/env bash

# ASDF Auto Install Script
# Tự động cài đặt các plugin và phiên bản mới nhất của các ngôn ngữ lập trình
# Universal compatibility: Bash, Zsh, Zsh+OhMyZsh

# Detect actual shell environment
ACTUAL_SHELL=""
HAS_OH_MY_ZSH=false

# Store original ZSH_VERSION before any modifications
ORIGINAL_ZSH_VERSION="$ZSH_VERSION"

if [[ -n "$ZSH_VERSION" ]]; then
    ACTUAL_SHELL="zsh"
    # Check for Oh My Zsh
    if [[ -n "$ZSH" ]] || [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        HAS_OH_MY_ZSH=true
    fi
    # Zsh compatibility: enable bash-like word splitting
    setopt SH_WORD_SPLIT 2>/dev/null || true
elif [[ -n "$BASH_VERSION" ]]; then
    ACTUAL_SHELL="bash"
    # Check if we're running bash but parent shell is zsh with Oh My Zsh
    if [[ -f "$HOME/.zshrc" ]] && grep -q "oh-my-zsh" "$HOME/.zshrc" 2>/dev/null; then
        HAS_OH_MY_ZSH=true
    fi
else
    ACTUAL_SHELL="unknown"
fi

set -e  # Dừng script nếu có lỗi

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hàm in thông báo với màu
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Hàm detect shell config file
detect_shell_config() {
    # Use original ZSH_VERSION or current shell detection
    if [[ -n "$ORIGINAL_ZSH_VERSION" ]] || [[ "$ACTUAL_SHELL" == "zsh" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

# Hàm thêm cấu hình ASDF vào file shell config
configure_asdf() {
    local shell_config=$(detect_shell_config)
    local config_content="
# ASDF Configuration
export ASDF_DIR=\"\$HOME/.asdf\"
export PATH=\"\$ASDF_DIR/bin:\$ASDF_DIR/shims:\$PATH\"
"
    
    echo "Đang thêm cấu hình ASDF vào $(basename "$shell_config")..."
    
    # Kiểm tra xem cấu hình đã tồn tại chưa
    if ! grep -q "ASDF Configuration" "$shell_config" 2>/dev/null; then
        echo "$config_content" >> "$shell_config"
        echo "Đã thêm cấu hình ASDF vào $(basename "$shell_config")"
    else
        echo "Cấu hình ASDF đã tồn tại trong $(basename "$shell_config")"
    fi
    
    echo "Khởi động lại shell hoặc chạy 'source $shell_config' để áp dụng cấu hình"
}

# Hàm source shell config - Smart sourcing với Oh My Zsh compatibility
source_shell_config() {
    local config_file=$(detect_shell_config)
    if [[ ! -f "$config_file" ]]; then
        return 0
    fi
    
    # Case 1: Running in Zsh (native or with Oh My Zsh) - safe to source
    if [[ "$ACTUAL_SHELL" == "zsh" ]]; then
        source "$config_file" 2>/dev/null || true
        return 0
    fi
    
    # Case 2: Running in Bash but need to source .zshrc
    if [[ "$config_file" == *".zshrc"* ]] && [[ "$ACTUAL_SHELL" == "bash" ]]; then
        if [[ "$HAS_OH_MY_ZSH" == "true" ]]; then
            # Oh My Zsh detected - create a safe source method
            print_info "Detected Oh My Zsh - using safe config sourcing..."
            # Extract only ASDF and certificate configs, skip Oh My Zsh
            {
                echo "# Temporary safe config sourcing"
                grep -E "^export (ASDF_|SSL_|REQUESTS_|CURL_|BUN_|DENO_)" "$config_file" 2>/dev/null || true
                grep -A5 -B5 "ASDF Configuration" "$config_file" 2>/dev/null || true
            } | bash 2>/dev/null || true
        else
            # No Oh My Zsh - safe to source directly
            source "$config_file" 2>/dev/null || true
        fi
        return 0
    fi
    
    # Case 3: Standard case - source normally
    source "$config_file" 2>/dev/null || true
}

# Cài đặt các gói cần thiết
install_required_packages() {
    print_info "Cài đặt các gói cần thiết (jq, gnupg)..."
    
    # Dọn dẹp cache và sửa lỗi dependency
    print_info "Dọn dẹp cache và sửa lỗi dependency..."
    sudo apt clean
    sudo apt autoclean
    sudo rm -rf /var/lib/apt/lists/*
    
    # Cập nhật danh sách gói
    if sudo apt update -y --fix-missing; then
        print_success "Đã cập nhật danh sách gói"
    else
        print_warning "Không thể cập nhật danh sách gói, tiếp tục cài đặt..."
    fi
    
    # Sửa lỗi gói bị hỏng trước
    print_info "Sửa lỗi gói bị hỏng..."
    sudo apt --fix-broken install -y
    
    # Cài đặt từng gói riêng biệt
    local packages=("jq" "gnupg")
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        print_info "Cài đặt $package..."
        if sudo apt install -y --fix-missing --fix-broken "$package"; then
            print_success "Đã cài đặt $package"
        else
            print_warning "Không thể cài đặt $package, thử cách khác..."
            # Thử cài đặt với --no-install-recommends
            if sudo apt install -y --fix-missing --fix-broken --no-install-recommends "$package"; then
                print_success "Đã cài đặt $package (không có gói khuyến nghị)"
            else
                failed_packages+=("$package")
                print_error "Không thể cài đặt $package"
            fi
        fi
    done
    
    # Kiểm tra kết quả
    if [ ${#failed_packages[@]} -gt 0 ]; then
        print_error "Các gói không thể cài đặt: ${failed_packages[*]}"
        print_info "Thử cài đặt thủ công: sudo apt install ${failed_packages[*]}"
        exit 1
    fi
    
    # Refresh PATH sau khi cài đặt
    hash -r
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    print_success "Đã cài đặt tất cả gói cần thiết"
    echo
}

# Hàm load config từ JSON
load_config() {
    local config_file="./plugins.json"
    if [ ! -f "$config_file" ]; then
        print_error "Không tìm thấy file cấu hình $config_file"
        exit 1
    fi
    
    # Parse JSON và tạo associative array
    declare -gA plugins
    declare -ga manual_version_plugins
    declare -gA recommended_versions
    
    # Load plugins
    while IFS='=' read -r key value; do
        plugins["$key"]="$value"
    done < <(jq -r '.plugins | to_entries[] | "\(.key)=\(.value)"' "$config_file")
    
    # Load manual version plugins
    while IFS= read -r plugin; do
        manual_version_plugins+=("$plugin")
    done < <(jq -r '.special_handling.manual_version[]' "$config_file")
    
    # Load recommended versions
    while IFS='=' read -r key value; do
        recommended_versions["$key"]="$value"
    done < <(jq -r '.special_handling.recommended_versions | to_entries[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null || true)
}

# Cấu hình ASDF trong shell config
configure_asdf_shell() {
    local config_content="
# ASDF Configuration
export ASDF_DIR=\"$HOME/.asdf\"
export PATH=\"$ASDF_DIR/bin:$ASDF_DIR/shims:$PATH\""
    
    local shell_config=$(detect_shell_config)
    
    print_info "Đang thêm cấu hình ASDF vào $(basename "$shell_config")..."
    
    # Kiểm tra xem cấu hình đã tồn tại chưa
    if ! grep -q "ASDF Configuration" "$shell_config" 2>/dev/null; then
        echo "$config_content" >> "$shell_config"
        print_success "Đã thêm cấu hình ASDF vào $(basename "$shell_config")"
    else
        print_warning "Cấu hình ASDF đã tồn tại trong $(basename "$shell_config")"
    fi
}

# Kiểm tra asdf đã được cài đặt chưa
check_asdf() {
    if ! command -v asdf &> /dev/null; then
        print_warning "asdf chưa được cài đặt."
        echo
        read -p "Nhập link tải asdf (ví dụ: https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz): " asdf_url
        
        if [ -z "$asdf_url" ]; then
            print_error "Link không được để trống"
            exit 1
        fi
        
        print_info "Đang tải và cài đặt asdf..."
        
        # Tạo thư mục tạm
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        # Tải file
        if curl -fsSL "$asdf_url" -o asdf.tar.gz; then
            print_success "Đã tải asdf"
        else
            print_error "Không thể tải asdf từ $asdf_url"
            exit 1
        fi
        
        # Giải nén
        if tar -xzf asdf.tar.gz; then
            print_success "Đã giải nén asdf"
        else
            print_error "Không thể giải nén asdf"
            exit 1
        fi
        
        # Tìm file thực thi asdf
        local asdf_bin=$(find . -name "asdf" -type f -executable | head -1)
        if [ -z "$asdf_bin" ]; then
            print_error "Không tìm thấy file thực thi asdf"
            exit 1
        fi
        
        # Sao chép vào /usr/local/bin
        if sudo cp "$asdf_bin" /usr/local/bin/asdf && sudo chmod +x /usr/local/bin/asdf; then
            print_success "Đã cài đặt asdf vào /usr/local/bin"
        else
            print_error "Không thể cài đặt asdf"
            exit 1
        fi
        
        # Dọn dẹp
        cd - > /dev/null
        rm -rf "$temp_dir"
        
        # Cấu hình ASDF trong shell config
        configure_asdf_shell
        
        # Khởi động lại shell
        print_info "Khởi động lại shell để áp dụng asdf..."
        source_shell_config
    fi
    print_success "asdf đã được cài đặt"
}

# Cài đặt chứng chỉ
setup_certificates() {
    print_info "Bước 0: Cài đặt chứng chỉ..."
    
    if [ -d "./certs" ]; then
        print_info "Đang sao chép chứng chỉ..."
        if sudo cp ./certs/* /usr/local/share/ca-certificates/ && sudo cp ./certs/* /etc/ssl/certs/; then
            print_success "Đã sao chép chứng chỉ"
        else
            print_error "Không thể sao chép chứng chỉ"
            return 1
        fi
        
        print_info "Đang cập nhật chứng chỉ..."
        if sudo update-ca-certificates; then
            print_success "Đã cập nhật chứng chỉ"
        else
            print_error "Không thể cập nhật chứng chỉ"
            return 1
        fi
        
        # Cấu hình biến môi trường chứng chỉ
        configure_shell_certificates
    else
        print_warning "Thư mục ./certs không tồn tại, bỏ qua bước cài đặt chứng chỉ"
    fi
    echo
}

# Cấu hình biến môi trường chứng chỉ trong shell config
configure_shell_certificates() {
    local config_content="
# CERTIFICATE BYPASS
export SSL_CERT_FILE=\"/etc/ssl/certs/ca-certificates.crt\"
export SSL_CERT_DIR=\"/etc/ssl/certs\"
export REQUESTS_CA_BUNDLE=\"/etc/ssl/certs/ca-certificates.crt\"
export CURL_CA_BUNDLE=\"/etc/ssl/certs/ca-certificates.crt\"

# Bun certificate configuration
export BUN_CA_BUNDLE_PATH=\"/etc/ssl/certs/ca-certificates.crt\"

# Deno certificate configuration
export DENO_CERT=\"/etc/ssl/certs/ca-certificates.crt\""
    
    local shell_config=$(detect_shell_config)
    
    print_info "Đang thêm cấu hình chứng chỉ vào $(basename "$shell_config")..."
    
    # Kiểm tra xem cấu hình đã tồn tại chưa
    if ! grep -q "CERTIFICATE BYPASS" "$shell_config" 2>/dev/null; then
        echo "$config_content" >> "$shell_config"
        print_success "Đã thêm cấu hình chứng chỉ vào $(basename "$shell_config")"
    else
        print_warning "Cấu hình chứng chỉ đã tồn tại trong $(basename "$shell_config")"
    fi
    
    # Khởi động lại shell để áp dụng cấu hình
    print_info "Khởi động lại shell để áp dụng cấu hình..."
    source_shell_config
}

# Cài đặt Docker và Podman
install_docker_podman() {
    print_info "Bước 0.5: Cài đặt Docker và Podman..."
    
    print_info "Cập nhật hệ thống..."
    if sudo apt update -y --fix-missing && sudo apt upgrade -y --fix-missing; then
        print_success "Đã cập nhật hệ thống"
    else
        print_error "Không thể cập nhật hệ thống"
        return 1
    fi
    
    print_info "Tạo thư mục keyrings..."
    if sudo mkdir -p /etc/apt/keyrings && sudo chmod 755 /etc/apt/keyrings; then
        print_success "Đã tạo thư mục keyrings"
    else
        print_error "Không thể tạo thư mục keyrings"
        return 1
    fi
    
    print_info "Thêm Docker GPG key..."
    # Kiểm tra gpg đã có chưa
    if ! command -v gpg >/dev/null 2>&1; then
        print_error "Lệnh gpg không khả dụng sau khi cài đặt"
        return 1
    fi
    
    if curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
        print_success "Đã thêm Docker GPG key"
        if sudo chmod a+r /etc/apt/keyrings/docker.gpg; then
            print_success "Đã đặt quyền cho Docker GPG key"
        else
            print_error "Không thể đặt quyền cho Docker GPG key"
            return 1
        fi
    else
        print_error "Không thể thêm Docker GPG key"
        return 1
    fi
    
    print_info "Thêm Docker repository..."
    if echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list; then
        print_success "Đã thêm Docker repository"
    else
        print_error "Không thể thêm Docker repository"
        return 1
    fi
    
    print_info "Cập nhật danh sách gói sau khi thêm repository..."
    if sudo apt update -y --fix-missing; then
        print_success "Đã cập nhật danh sách gói"
    else
        print_error "Không thể cập nhật danh sách gói"
        return 1
    fi
    
    print_info "Xóa gói xung đột docker-buildx nếu tồn tại..."
    if dpkg -l | grep -q docker-buildx; then
        if sudo apt remove -y docker-buildx; then
            print_success "Đã xóa gói docker-buildx"
        else
            print_error "Không thể xóa gói docker-buildx"
            return 1
        fi
    else
        print_info "Không tìm thấy gói docker-buildx, bỏ qua xóa"
    fi
    
    print_info "Sửa lỗi gói bị hỏng (nếu có)..."
    if sudo apt install -f -y --fix-missing --fix-broken; then
        print_success "Đã sửa lỗi gói bị hỏng"
    else
        print_error "Không thể sửa lỗi gói bị hỏng"
        return 1
    fi
    
    print_info "Cài đặt các gói phụ thuộc bổ sung..."
    if sudo apt install -y --fix-missing --fix-broken build-essential unzip autoconf libncurses5-dev libssl-dev ca-certificates curl liblzma-dev snapd python3-tk; then
        print_success "Đã cài đặt các gói phụ thuộc bổ sung"
    else
        print_error "Không thể cài đặt các gói phụ thuộc bổ sung"
        return 1
    fi
    
    print_info "Cài đặt Docker và Podman..."
    if sudo apt install -y --fix-missing --fix-broken podman docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        print_success "Đã cài đặt Docker và Podman"
    else
        print_error "Không thể cài đặt Docker và Podman"
        return 1
    fi
    
    echo
}

# Hàm thêm plugin
add_plugin() {
    local plugin_name=$1
    local plugin_url=$2
    
    print_info "Đang thêm plugin: $plugin_name"
    
    if asdf plugin list | grep -q "^$plugin_name$"; then
        print_warning "Plugin $plugin_name đã tồn tại, bỏ qua..."
        return 0
    fi
    
    if [ -n "$plugin_url" ]; then
        if asdf plugin add "$plugin_name" "$plugin_url"; then
            print_success "Đã thêm plugin $plugin_name"
        else
            print_error "Không thể thêm plugin $plugin_name"
            return 1
        fi
    else
        if asdf plugin add "$plugin_name"; then
            print_success "Đã thêm plugin $plugin_name"
        else
            print_error "Không thể thêm plugin $plugin_name"
            return 1
        fi
    fi
}

# Hàm cài đặt phiên bản mới nhất
install_latest() {
    local plugin_name=$1
    local version=""
    
    # Kiểm tra xem plugin có cần nhập version thủ công không
    local needs_manual=false
    for manual_plugin in "${manual_version_plugins[@]}"; do
        if [ "$plugin_name" = "$manual_plugin" ]; then
            needs_manual=true
            break
        fi
    done
    
    if [ "$needs_manual" = true ]; then
        print_info "Đang lấy danh sách phiên bản cho $plugin_name..."
        if ! asdf list all "$plugin_name"; then
            print_error "Không thể lấy danh sách phiên bản của $plugin_name"
            return 1
        fi
        
        echo
        local prompt="Nhập phiên bản $plugin_name bạn muốn cài đặt"
        if [ -n "${recommended_versions[$plugin_name]}" ]; then
            prompt="$prompt (khuyến nghị: ${recommended_versions[$plugin_name]})"
        fi
        read -p "$prompt: " version
        
        if [ -z "$version" ]; then
            print_error "Phiên bản không được để trống"
            return 1
        fi
        
        print_info "Đang cài đặt $plugin_name phiên bản $version..."
    else
        # Lấy phiên bản mới nhất từ asdf
        version=$(asdf latest "$plugin_name")
        if [ -z "$version" ]; then
            print_error "Không thể lấy được phiên bản mới nhất của $plugin_name"
            return 1
        fi
        print_info "Đang cài đặt $plugin_name phiên bản $version..."
    fi
    
    if asdf install "$plugin_name" "$version"; then
        print_success "Đã cài đặt $plugin_name phiên bản $version"
        
        # Đặt phiên bản trong home directory
        if asdf set -u "$plugin_name" "$version" --home; then
            print_success "Đã đặt $plugin_name $version làm phiên bản mặc định trong home directory"
        else
            print_warning "Không thể đặt $plugin_name $version làm phiên bản mặc định"
        fi
    else
        print_error "Không thể cài đặt $plugin_name"
        return 1
    fi
}

# Sửa lỗi Zig plugin
fix_zig_plugin() {
    print_info "Kiểm tra và sửa lỗi Zig plugin..."
    
    # Kiểm tra xem zig có được cài đặt thành công không
    if asdf list zig 2>/dev/null | grep -q "[0-9]"; then
        print_success "Zig đã được cài đặt thành công"
        return 0
    fi
    
    print_warning "Zig chưa được cài đặt thành công, đang sửa lỗi..."
    
    local zig_utils_path="$HOME/.asdf/plugins/zig/lib/utils.py"
    
    if [ ! -f "$zig_utils_path" ]; then
        print_error "Không tìm thấy file $zig_utils_path"
        return 1
    fi
    
    # Tạo nội dung file mới
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
 
# https://github.com/mlugg/setup-zig/blob/main/mirrors.json
# If any of these mirrors are down, please open an issue!
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
    chunk_size = 1024 * 1024 # 1M chunks
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
                    break  # eof
                sha256_hash.update(chunk)
                f.write(chunk)
 
    actual = sha256_hash.hexdigest()
    if actual != expected_shasum:
        raise Exception(
            f"Shasum not match, expected:{expected_shasum}, actual:{actual}"
        )
 
 
def download_tarball(url, out_file, expected_shasum, total_size):
    filename = url.split("/")[-1]
    random.shuffle(MIRRORS)
 
    for mirror in MIRRORS:
        try:
            # Ensure base_url has a trailing slash
            mirror = mirror if mirror.endswith('/') else mirror + '/'
            download_and_check(urljoin(mirror, filename), out_file, expected_shasum, total_size)
            return
        except Exception as e:
            logging.error(f"Current mirror failed, try next. err:{e}")
 
    # All mirrors failed, fallback to original url
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
    
    print_success "Đã ghi đè file utils.py cho Zig plugin"
    echo
}

# Cấu hình các công cụ với chứng chỉ SSL
configure_tools() {
    print_info "Cấu hình các công cụ với chứng chỉ SSL..."
    
    # Node.js/npm configuration
    print_info "Cấu hình npm..."
    npm config set cafile /etc/ssl/certs/ca-certificates.crt 2>/dev/null || true
    npm config set strict-ssl true 2>/dev/null || true
    
    # Git configuration
    print_info "Cấu hình Git..."
    git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt 2>/dev/null || true
    git config --global http.sslVerify true 2>/dev/null || true
    
    # Wget configuration
    print_info "Cấu hình Wget..."
    echo "ca_certificate = /etc/ssl/certs/ca-certificates.crt" >> ~/.wgetrc
    
    # Rust/Cargo configuration
    print_info "Cấu hình Cargo..."
    cargo config --global http.cainfo /etc/ssl/certs/ca-certificates.crt 2>/dev/null || true
    
    # Go configuration
    print_info "Cấu hình Go..."
    go env -w GOPROXY=direct 2>/dev/null || true
    
    # Java configuration
    print_info "Cấu hình Java..."
    if command -v keytool >/dev/null 2>&1; then
        sudo keytool -import -trustcacerts -keystore $(find /usr -name cacerts 2>/dev/null | head -1) -storepass changeit -alias company-root -file /usr/local/share/ca-certificates/*.crt -noprompt 2>/dev/null || true
    fi
    
    # Elixir/Erlang configuration
    print_info "Cấu hình Elixir/Erlang..."
    mkdir -p ~/.config/hex
    echo 'unsafe_https: false' > ~/.config/hex/hex.config
    
    # Python/pip configuration
    print_info "Cấu hình Python/pip..."
    mkdir -p ~/.config/pip
    cat > ~/.config/pip/pip.conf << EOF
[global]
cert = /etc/ssl/certs/ca-certificates.crt
EOF
    
    # Flutter configuration
    print_info "Cấu hình Flutter..."
    if command -v flutter >/dev/null 2>&1; then
        flutter config --no-analytics 2>/dev/null || true
    fi
    
    print_success "Đã cấu hình tất cả các công cụ"
    echo
}

# Main script
main() {
    print_info "=== ASDF Auto Install Script - Universal Compatibility ==="
    print_info "Shell Environment: $ACTUAL_SHELL"
    print_info "Oh My Zsh: $HAS_OH_MY_ZSH"
    print_info "Target Config: $(detect_shell_config)"
    echo
    
    print_info "Bắt đầu cài đặt các plugin asdf và ngôn ngữ lập trình..."
    echo
    
    # Cài đặt chứng chỉ
    setup_certificates

    # Cài đặt các gói cần thiết trước
    install_required_packages
    
    # Load cấu hình từ JSON
    load_config
    
    # Cài đặt Docker và Podman
    install_docker_podman
    
    # Kiểm tra asdf
    check_asdf
    echo
    
    # Thêm tất cả các plugin
    print_info "Bước 1: Thêm các plugin..."
    echo
    failed_plugins=()
    
    for plugin in "${!plugins[@]}"; do
        if ! add_plugin "$plugin" "${plugins[$plugin]}"; then
            failed_plugins+=("$plugin")
        fi
    done
    
    echo
    print_info "Bước 2: Cài đặt phiên bản mới nhất..."
    echo
    
    # Cài đặt phiên bản mới nhất cho các plugin đã thêm thành công
    failed_installs=()
    
    for plugin in "${!plugins[@]}"; do
        # Bỏ qua các plugin không thêm được
        if [[ " ${failed_plugins[*]} " =~ " $plugin " ]]; then
            print_warning "Bỏ qua cài đặt $plugin vì plugin không thể thêm được"
            continue
        fi
        
        if ! install_latest "$plugin"; then
            failed_installs+=("$plugin")
        fi
        echo
    done
    
    # Kiểm tra và sửa lỗi Zig plugin
    fix_zig_plugin
    
    # Cấu hình các công cụ
    configure_tools
    configure_asdf
    
    # Tóm tắt kết quả
    echo
    print_info "=== TÓM TẮT KẾT QUẢ ==="
    
    if [ ${#failed_plugins[@]} -eq 0 ] && [ ${#failed_installs[@]} -eq 0 ]; then
        print_success "Tất cả plugin và ngôn ngữ đã được cài đặt thành công!"
    else
        if [ ${#failed_plugins[@]} -gt 0 ]; then
            print_error "Các plugin không thể thêm được: ${failed_plugins[*]}"
        fi
        
        if [ ${#failed_installs[@]} -gt 0 ]; then
            print_error "Các ngôn ngữ không thể cài đặt được: ${failed_installs[*]}"
        fi
    fi
    
    echo
    print_info "Chạy 'asdf list' để xem các phiên bản đã cài đặt"
    print_info "Chạy 'asdf current' để xem các phiên bản hiện tại"
    
    # Smart final configuration based on shell environment
    local config_file=$(detect_shell_config)
    print_info "Configuration written to: $config_file"
    
    case "$ACTUAL_SHELL" in
        "zsh")
            print_success "Zsh detected - applying configuration..."
            source_shell_config
            if [[ "$HAS_OH_MY_ZSH" == "true" ]]; then
                print_info "Oh My Zsh environment - restart terminal or run: exec zsh"
            else
                exec zsh
            fi
            ;;
        "bash")
            if [[ "$HAS_OH_MY_ZSH" == "true" ]]; then
                print_warning "Oh My Zsh detected but running in Bash"
                print_info "For best experience, switch to Zsh: exec zsh"
                print_info "Or restart terminal"
            else
                print_success "Bash environment - applying configuration..."
                source_shell_config
                exec bash
            fi
            ;;
        *)
            print_warning "Unknown shell environment"
            print_info "Please restart terminal or source config manually: source $config_file"
            ;;
    esac
}

# Chạy script
main "$@"