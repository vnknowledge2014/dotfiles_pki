#!/usr/bin/env zsh

# ASDF Auto Install Script for Zsh
# Tự động cài đặt các plugin và phiên bản mới nhất của các ngôn ngữ lập trình
# Optimized for Zsh with enhanced features

# Enable Zsh options for better script behavior
setopt EXTENDED_GLOB
setopt NULL_GLOB
setopt GLOB_DOTS
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS

# Global variables (initialize early)
typeset -gA plugins
typeset -ga manual_version_plugins
typeset -gA recommended_versions

# Error handling - safer approach
# Note: set -e can cause issues with some functions, so we handle errors manually

# Colors for output (Zsh enhanced)
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -U colors && colors
fi

# Enhanced printing functions with Zsh features
print_info() {
    if [[ -n "$ZSH_VERSION" ]]; then
        print -P "%F{blue}[INFO]%f $1"
    else
        printf "\033[0;34m[INFO]\033[0m %s\n" "$1"
    fi
}

print_success() {
    if [[ -n "$ZSH_VERSION" ]]; then
        print -P "%F{green}[SUCCESS]%f $1"
    else
        printf "\033[0;32m[SUCCESS]\033[0m %s\n" "$1"
    fi
}

print_warning() {
    if [[ -n "$ZSH_VERSION" ]]; then
        print -P "%F{yellow}[WARNING]%f $1"
    else
        printf "\033[1;33m[WARNING]\033[0m %s\n" "$1"
    fi
}

print_error() {
    if [[ -n "$ZSH_VERSION" ]]; then
        print -P "%F{red}[ERROR]%f $1"
    else
        printf "\033[0;31m[ERROR]\033[0m %s\n" "$1" >&2
    fi
}

print_step() {
    if [[ -n "$ZSH_VERSION" ]]; then
        print -P "%F{cyan}%B[STEP $1]%b%f $2"
    else
        printf "\033[0;36m\033[1m[STEP %s]\033[0m %s\n" "$1" "$2"
    fi
}

print_substep() {
    if [[ -n "$ZSH_VERSION" ]]; then
        print -P "  %F{magenta}→%f $1"
    else
        printf "  \033[0;35m→\033[0m %s\n" "$1"
    fi
}

# Safe progress bar function
show_progress() {
    local current=$1
    local total=$2
    local description=$3
    
    # Input validation
    if [[ ! "$current" =~ ^[0-9]+$ ]] || [[ ! "$total" =~ ^[0-9]+$ ]]; then
        print_error "Invalid progress values: current=$current, total=$total"
        return 1
    fi
    
    # Prevent division by zero
    if [[ $total -eq 0 ]]; then
        printf "\r%s [--------------------------------------------------] 0%%" "$description"
        return 0
    fi
    
    # Ensure current doesn't exceed total
    if [[ $current -gt $total ]]; then
        current=$total
    fi
    
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r%s [" "$description"
    printf "%*s" $filled | tr ' ' '='
    printf "%*s" $empty | tr ' ' '-'
    printf "] %d%%" $percent
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Zsh-specific configuration detection
detect_zsh_config() {
    local config_files=()
    
    # Check for common Zsh config files in order of preference
    [[ -f "$HOME/.zshrc" ]] && config_files+=("$HOME/.zshrc")
    [[ -f "$HOME/.zprofile" ]] && config_files+=("$HOME/.zprofile")
    [[ -f "$HOME/.zshenv" ]] && config_files+=("$HOME/.zshenv")
    
    # Default to .zshrc if none exist
    if [[ ${#config_files[@]} -eq 0 ]]; then
        config_files=("$HOME/.zshrc")
    fi
    
    # Return the first existing config file or .zshrc as default
    echo "${config_files[1]}"
}

# Detect Zsh plugin manager
detect_zsh_plugin_manager() {
    local managers=()
    
    # Check for popular Zsh plugin managers
    [[ -d "$HOME/.oh-my-zsh" ]] && managers+=("oh-my-zsh")
    [[ -f "$HOME/.zpreztorc" ]] && managers+=("prezto")
    [[ -d "$HOME/.zinit" ]] && managers+=("zinit")
    [[ -d "$HOME/.config/zsh/plugins" ]] && managers+=("manual")
    
    if [[ ${#managers[@]} -gt 0 ]]; then
        echo "${managers[1]}"
    else
        echo "none"
    fi
}

# Simple ASDF shell configuration (matching index.sh logic)
configure_asdf_shell_zsh() {
    local config_content="
# ASDF Configuration
export ASDF_DIR=\"\$HOME/.asdf\"
export PATH=\"\$ASDF_DIR/bin:\$ASDF_DIR/shims:\$PATH\""
    
    local shell_config=$(detect_zsh_config)
    
    print_info "Đang thêm cấu hình ASDF vào $(basename "$shell_config")..."
    
    # Kiểm tra xem cấu hình đã tồn tại chưa
    if ! grep -q "ASDF Configuration" "$shell_config" 2>/dev/null; then
        echo "$config_content" >> "$shell_config"
        print_success "Đã thêm cấu hình ASDF vào $(basename "$shell_config")"
    else
        print_warning "Cấu hình ASDF đã tồn tại trong $(basename "$shell_config")"
    fi
}

# Source shell config (matching index.sh logic)
source_shell_config_zsh() {
    local config_file=$(detect_zsh_config)
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

# Enhanced certificate configuration for Zsh
configure_shell_certificates_zsh() {
    local shell_config=$(detect_zsh_config)
    
    print_info "Configuring certificates for Zsh..."
    
    # Enhanced certificate configuration with Zsh arrays
    local cert_config="
# Certificate Configuration for Zsh
typeset -gx SSL_CERT_FILE=\"/etc/ssl/certs/ca-certificates.crt\"
typeset -gx SSL_CERT_DIR=\"/etc/ssl/certs\"
typeset -gx REQUESTS_CA_BUNDLE=\"/etc/ssl/certs/ca-certificates.crt\"
typeset -gx CURL_CA_BUNDLE=\"/etc/ssl/certs/ca-certificates.crt\"

# Tool-specific certificate configurations
typeset -gx BUN_CA_BUNDLE_PATH=\"/etc/ssl/certs/ca-certificates.crt\"
typeset -gx DENO_CERT=\"/etc/ssl/certs/ca-certificates.crt\"
typeset -gx NODE_EXTRA_CA_CERTS=\"/etc/ssl/certs/ca-certificates.crt\"
typeset -gx PYTHONHTTPSVERIFY=\"1\"

# Zsh-specific certificate array for easy management
typeset -ga cert_paths=(\"/etc/ssl/certs/ca-certificates.crt\" \"/usr/local/share/ca-certificates\")

# Function to validate certificates
validate_certs() {
    local cert_file
    for cert_file in \$cert_paths; do
        if [[ -f \$cert_file ]]; then
            print -P \"%F{green}✓%f Certificate found: \$cert_file\"
        else
            print -P \"%F{red}✗%f Certificate missing: \$cert_file\"
        fi
    done
}"
    
    # Add to shell config if not already present
    if ! grep -q "Certificate Configuration for Zsh" "$shell_config" 2>/dev/null; then
        echo "$cert_config" >> "$shell_config"
        print_success "Added certificate configuration to $(basename "$shell_config")"
    else
        print_warning "Certificate configuration already exists in $(basename "$shell_config")"
    fi
}

# Enhanced package installation with Zsh arrays
install_required_packages_zsh() {
    print_info "Cài đặt các gói cần thiết (jq, gnupg)..."
    
    # Check operating system
    local os_type=$(uname -s)
    case "$os_type" in
        "Linux")
            # Check if we have the required commands
            if ! command -v sudo >/dev/null 2>&1; then
                print_error "sudo is required but not found"
                return 1
            fi
            
            if ! command -v apt >/dev/null 2>&1; then
                print_error "apt is required but not found (Debian/Ubuntu only)"
                return 1
            fi
            ;;
        "Darwin")
            print_warning "Running on macOS - skipping package installation"
            print_info "Please ensure you have jq and gnupg installed:"
            print_info "  brew install jq gnupg"
            return 0
            ;;
        *)
            print_warning "Unsupported operating system: $os_type"
            print_info "Please ensure you have jq and gnupg installed manually"
            return 0
            ;;
    esac
    
    # Zsh array of required packages
    local required_packages=(
        jq
        gnupg
        curl
        wget
        git
        build-essential
        unzip
        autoconf
        libncurses5-dev
        libssl-dev
        ca-certificates
        software-properties-common
    )
    
    # Optional packages that enhance Zsh experience
    local optional_packages=(
        zsh-syntax-highlighting
        zsh-autosuggestions
        zsh-completions
        fzf
        ripgrep
        fd-find
        bat
        exa
    )
    
    print_substep "Cleaning package cache..."
    sudo apt clean 2>/dev/null || true
    sudo apt autoclean 2>/dev/null || true
    sudo rm -rf /var/lib/apt/lists/* 2>/dev/null || true
    
    print_substep "Updating package lists..."
    if sudo apt update -y --fix-missing 2>/dev/null; then
        print_success "Package lists updated"
    else
        print_warning "Package list update failed, continuing..."
    fi
    
    # Install required packages
    print_substep "Installing required packages..."
    local failed_packages=()
    local installed_count=0
    
    for package in "${required_packages[@]}"; do
        ((installed_count++))
        show_progress $installed_count ${#required_packages[@]} "Installing $package"
        
        if sudo apt install -y --fix-missing --fix-broken "$package" >/dev/null 2>&1; then
            continue
        else
            failed_packages+=("$package")
            print_error "Failed to install $package"
        fi
    done
    
    # Install optional packages (non-critical)
    print_substep "Installing optional Zsh enhancements..."
    local optional_installed=0
    
    for package in "${optional_packages[@]}"; do
        if sudo apt install -y "$package" >/dev/null 2>&1; then
            ((optional_installed++))
        fi
    done
    
    print_success "Installed $optional_installed optional packages"
    
    # Check for failures
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_error "Failed to install: ${(j:, :)failed_packages}"
        print_info "Try manual installation: sudo apt install ${(j: :)failed_packages}"
        return 1
    fi
    
    print_success "All required packages installed"
    return 0
}

# Enhanced JSON configuration loading with Zsh
load_config_zsh() {
    local config_file="./plugins.json"
    
    print_info "Đang tải cấu hình..."
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required but not found"
        return 1
    fi
    
    print_substep "Loading plugins configuration..."
    
    # Load plugins into associative array
    local plugin_data
    plugin_data=$(jq -r '.plugins | to_entries[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null)
    
    if [[ -z "$plugin_data" ]]; then
        print_error "Failed to parse plugins from $config_file"
        return 1
    fi
    
    while IFS='=' read -r key value; do
        [[ -n "$key" ]] && plugins[$key]=$value
    done <<< "$plugin_data"
    
    # Load manual version plugins
    local manual_plugins
    manual_plugins=$(jq -r '.special_handling.manual_version[]' "$config_file" 2>/dev/null)
    
    while IFS= read -r plugin; do
        [[ -n "$plugin" ]] && manual_version_plugins+=("$plugin")
    done <<< "$manual_plugins"
    
    # Load recommended versions
    local recommended_data
    recommended_data=$(jq -r '.special_handling.recommended_versions | to_entries[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null)
    
    while IFS='=' read -r key value; do
        [[ -n "$key" ]] && recommended_versions[$key]=$value
    done <<< "$recommended_data"
    
    print_success "Configuration loaded: ${#plugins[@]} plugins, ${#manual_version_plugins[@]} manual"
    return 0
}

# Enhanced certificate setup with Zsh features
setup_certificates_zsh() {
    print_info "Bước 0: Cài đặt chứng chỉ..."
    
    local cert_dir="./certs"
    
    if [[ ! -d "$cert_dir" ]]; then
        print_warning "Certificate directory not found: $cert_dir"
        return 0
    fi
    
    # Find certificate files using Zsh glob patterns
    local cert_files=($cert_dir/**/*.(crt|pem|cer)(N))
    
    if [[ ${#cert_files[@]} -eq 0 ]]; then
        print_warning "No certificate files found in $cert_dir"
        return 0
    fi
    
    print_substep "Found ${#cert_files[@]} certificate files"
    
    # Check operating system for certificate installation
    local os_type=$(uname -s)
    case "$os_type" in
        "Linux")
            # Copy certificates to system locations
            print_substep "Installing certificates to system (Linux)..."
            
            for cert_file in "${cert_files[@]}"; do
                local filename=$(basename "$cert_file")
                print_substep "Installing $filename"
                
                if sudo cp "$cert_file" "/usr/local/share/ca-certificates/" 2>/dev/null; then
                    sudo cp "$cert_file" "/etc/ssl/certs/" 2>/dev/null || true
                else
                    print_error "Failed to copy $filename"
                fi
            done
            
            print_substep "Updating certificate store..."
            if sudo update-ca-certificates 2>/dev/null; then
                print_success "Certificate store updated"
            else
                print_error "Failed to update certificate store"
                return 1
            fi
            ;;
        "Darwin")
            print_warning "Running on macOS - certificate installation requires manual setup"
            print_info "To install certificates on macOS:"
            for cert_file in "${cert_files[@]}"; do
                local filename=$(basename "$cert_file")
                print_info "  security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain '$cert_file'"
            done
            ;;
        *)
            print_warning "Unsupported OS for automatic certificate installation: $os_type"
            print_info "Please install certificates manually for your system"
            ;;
    esac
    
    # Configure certificate environment
    configure_shell_certificates_zsh
    
    print_success "Certificates configured"
    return 0
}

# Check ASDF installation (exact logic from index.sh, adapted for Zsh)
check_asdf_zsh() {
    if ! command -v asdf &> /dev/null; then
        print_warning "asdf chưa được cài đặt."
        echo
        
        # Zsh-specific read command
        read "asdf_url?Nhập link tải asdf (ví dụ: https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz): "
        
        if [[ -z "$asdf_url" ]]; then
            print_error "Link không được để trống"
            exit 1
        fi
        
        print_info "Đang tải và cài đặt asdf..."
        
        # Tạo thư mục tạm
        local temp_dir=$(mktemp -d)
        local original_dir=$(pwd)
        cd "$temp_dir"
        
        # Tải file
        if curl -fsSL "$asdf_url" -o asdf.tar.gz; then
            print_success "Đã tải asdf"
        else
            print_error "Không thể tải asdf từ $asdf_url"
            cd "$original_dir"
            rm -rf "$temp_dir"
            exit 1
        fi
        
        # Giải nén
        if tar -xzf asdf.tar.gz; then
            print_success "Đã giải nén asdf"
        else
            print_error "Không thể giải nén asdf"
            cd "$original_dir"
            rm -rf "$temp_dir"
            exit 1
        fi
        
        # Tìm file thực thi asdf (Zsh-specific find)
        local asdf_bin=$(find . -name "asdf" -type f -executable | head -1)
        if [[ -z "$asdf_bin" ]]; then
            print_error "Không tìm thấy file thực thi asdf"
            cd "$original_dir"
            rm -rf "$temp_dir"
            exit 1
        fi
        
        # Sao chép vào /usr/local/bin
        if sudo cp "$asdf_bin" /usr/local/bin/asdf && sudo chmod +x /usr/local/bin/asdf; then
            print_success "Đã cài đặt asdf vào /usr/local/bin"
        else
            print_error "Không thể cài đặt asdf"
            cd "$original_dir"
            rm -rf "$temp_dir"
            exit 1
        fi
        
        # Dọn dẹp
        cd "$original_dir"
        rm -rf "$temp_dir"
        
        # Cấu hình ASDF trong shell config
        configure_asdf_shell_zsh
        
        # Khởi động lại shell
        print_info "Khởi động lại shell để áp dụng asdf..."
        source_shell_config_zsh
    fi
    print_success "asdf đã được cài đặt"
}

# Enhanced plugin addition with Zsh progress tracking
add_plugin_zsh() {
    local plugin_name=$1
    local plugin_url=$2
    
    print_substep "Adding plugin: $plugin_name"
    
    # Check if plugin already exists
    if asdf plugin list 2>/dev/null | grep -q "^$plugin_name$"; then
        print_warning "Plugin $plugin_name already exists"
        return 0
    fi
    
    # Add plugin with timeout
    if timeout 30 asdf plugin add "$plugin_name" "$plugin_url" 2>/dev/null; then
        print_success "Added plugin: $plugin_name"
        return 0
    else
        print_error "Failed to add plugin: $plugin_name"
        return 1
    fi
}

# Enhanced version installation with Zsh menu selection
install_latest_zsh() {
    local plugin_name=$1
    local version=""
    
    print_substep "Installing $plugin_name..."
    
    # Check if manual version is required
    if [[ " ${manual_version_plugins[*]} " =~ " $plugin_name " ]]; then
        print_info "Manual version selection required for $plugin_name"
        
        # Get available versions
        local versions=($(asdf list all "$plugin_name" 2>/dev/null | tail -10))
        
        if [[ ${#versions[@]} -eq 0 ]]; then
            print_error "No versions available for $plugin_name"
            return 1
        fi
        
        # Use recommended version if available
        if [[ -n "${recommended_versions[$plugin_name]:-}" ]]; then
            version="${recommended_versions[$plugin_name]}"
            print_info "Using recommended version: $version"
        else
            # Use latest version as fallback
            version="${versions[-1]}"
            print_info "Using latest version: $version"
        fi
    else
        # Get latest version automatically
        version=$(asdf latest "$plugin_name" 2>/dev/null)
        if [[ -z "$version" ]]; then
            print_error "Could not determine latest version for $plugin_name"
            return 1
        fi
    fi
    
    print_substep "Installing $plugin_name version $version..."
    
    # Install with progress indication
    if asdf install "$plugin_name" "$version" 2>/dev/null; then
        print_success "Installed $plugin_name $version"
        
        # Set global version
        if asdf global "$plugin_name" "$version" 2>/dev/null; then
            print_success "Set $plugin_name $version as global"
        else
            print_warning "Failed to set global version for $plugin_name"
        fi
        
        return 0
    else
        print_error "Failed to install $plugin_name $version"
        return 1
    fi
}

# Enhanced tool configuration with Zsh
configure_tools_zsh() {
    print_info "Cấu hình các công cụ với chứng chỉ SSL..."
    
    local tools_config=(
        "npm:npm config set cafile /etc/ssl/certs/ca-certificates.crt"
        "npm:npm config set strict-ssl true"
        "git:git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt"
        "git:git config --global http.sslVerify true"
        "cargo:mkdir -p ~/.cargo"
        "cargo:echo '[http]' > ~/.cargo/config.toml"
        "cargo:echo 'cainfo = \"/etc/ssl/certs/ca-certificates.crt\"' >> ~/.cargo/config.toml"
        "pip:mkdir -p ~/.config/pip"
        "pip:echo '[global]' > ~/.config/pip/pip.conf"
        "pip:echo 'cert = /etc/ssl/certs/ca-certificates.crt' >> ~/.config/pip/pip.conf"
    )
    
    for config in "${tools_config[@]}"; do
        local tool="${config%%:*}"
        local command="${config#*:}"
        
        print_substep "Configuring $tool..."
        
        if eval "$command" 2>/dev/null; then
            print_success "$tool configured"
        else
            print_warning "Failed to configure $tool"
        fi
    done
}

# Enhanced main function with Zsh features
main_zsh() {
    print -P "%F{cyan}%B════════════════════════════════════════════════════════════════════════════════%b%f"
    print -P "%F{cyan}%B                     ASDF Auto Install Script for Zsh                           %b%f"
    print -P "%F{cyan}%B════════════════════════════════════════════════════════════════════════════════%b%f"
    
    local start_time=$(date +%s)
    
    # Check if running in Zsh
    if [[ -z "$ZSH_VERSION" ]]; then
        print_error "This script is designed for Zsh. Please run with: zsh index_zsh.sh"
        exit 1
    fi
    
    print_info "Starting ASDF installation process..."
    print_info "Detected Zsh version: $ZSH_VERSION"
    print_info "Operating system: $(uname -s)"
    
    # Check for test mode
    if [[ "$1" == "--test" ]]; then
        print_warning "Running in test mode - no actual installation will occur"
        print_info "Test mode completed successfully"
        return 0
    fi
    
    # Execute main steps with error handling
    setup_certificates_zsh || { print_error "Certificate setup failed"; exit 1; }
    install_required_packages_zsh || { print_error "Package installation failed"; exit 1; }
    load_config_zsh || { print_error "Configuration loading failed"; exit 1; }
    check_asdf_zsh || { print_error "ASDF installation failed"; exit 1; }
    
    # Install plugins and languages  
    print_info "Bước 1: Thêm các plugin..."
    
    local failed_plugins=()
    local plugin_count=0
    
    for plugin_name in "${(@k)plugins}"; do
        ((plugin_count++))
        show_progress $plugin_count ${#plugins[@]} "Processing plugins"
        
        if ! add_plugin_zsh "$plugin_name" "${plugins[$plugin_name]}"; then
            failed_plugins+=("$plugin_name")
        fi
    done
    
    print_info "Bước 2: Cài đặt phiên bản mới nhất..."
    
    local failed_installs=()
    local install_count=0
    local successful_plugins=()
    
    for plugin_name in "${(@k)plugins}"; do
        if [[ ! " ${failed_plugins[*]} " =~ " $plugin_name " ]]; then
            successful_plugins+=("$plugin_name")
        fi
    done
    
    for plugin_name in "${successful_plugins[@]}"; do
        ((install_count++))
        show_progress $install_count ${#successful_plugins[@]} "Installing versions"
        
        if ! install_latest_zsh "$plugin_name"; then
            failed_installs+=("$plugin_name")
        fi
    done
    
    # Configure tools
    configure_tools_zsh
    
    # Final summary
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print -P "%F{cyan}%B════════════════════════════════════════════════════════════════════════════════%b%f"
    print -P "%F{cyan}%B                              INSTALLATION SUMMARY                               %b%f"
    print -P "%F{cyan}%B════════════════════════════════════════════════════════════════════════════════%b%f"
    
    print_info "Installation completed in ${duration}s"
    print_info "Total plugins: ${#plugins[@]}"
    print_info "Successfully installed: $((${#plugins[@]} - ${#failed_plugins[@]} - ${#failed_installs[@]}))"
    
    if [[ ${#failed_plugins[@]} -gt 0 ]]; then
        print_error "Failed to add plugins: ${(j:, :)failed_plugins}"
    fi
    
    if [[ ${#failed_installs[@]} -gt 0 ]]; then
        print_error "Failed to install: ${(j:, :)failed_installs}"
    fi
    
    print_info "Next steps:"
    print_substep "Run 'exec zsh' to restart your shell"
    print_substep "Run 'asdf list' to see installed versions"
    print_substep "Run 'asdf current' to see active versions"
    print_substep "Run 'validate_certs' to check certificate configuration"
    
    print_success "Setup complete! Welcome to your new development environment!"
}

# Execute main function only if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${0}" == *"index_zsh.sh" ]]; then
    main_zsh "$@"
fi