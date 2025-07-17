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

# Error handling
set -e  # Exit on error
trap 'print_error "Script failed at line $LINENO"' ERR

# Colors for output (Zsh enhanced)
autoload -U colors && colors
typeset -A color_codes
color_codes=(
    RED     $'\033[0;31m'
    GREEN   $'\033[0;32m'
    YELLOW  $'\033[1;33m'
    BLUE    $'\033[0;34m'
    MAGENTA $'\033[0;35m'
    CYAN    $'\033[0;36m'
    BOLD    $'\033[1m'
    NC      $'\033[0m'
)

# Enhanced printing functions with Zsh features
print_info() {
    print -P "%F{blue}[INFO]%f $1"
}

print_success() {
    print -P "%F{green}[SUCCESS]%f $1"
}

print_warning() {
    print -P "%F{yellow}[WARNING]%f $1"
}

print_error() {
    print -P "%F{red}[ERROR]%f $1"
}

print_step() {
    print -P "%F{cyan}%B[STEP $1]%b%f $2"
}

print_substep() {
    print -P "  %F{magenta}→%f $1"
}

# Progress bar function (Zsh specific)
show_progress() {
    local current=$1
    local total=$2
    local description=$3
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

# Enhanced ASDF configuration for Zsh
configure_asdf_zsh() {
    local shell_config=$(detect_zsh_config)
    local plugin_manager=$(detect_zsh_plugin_manager)
    
    print_info "Configuring ASDF for Zsh..."
    print_substep "Config file: $(basename "$shell_config")"
    print_substep "Plugin manager: $plugin_manager"
    
    # Base ASDF configuration
    local asdf_config="
# ASDF Configuration for Zsh
export ASDF_DIR=\"\$HOME/.asdf\"
export PATH=\"\$ASDF_DIR/bin:\$ASDF_DIR/shims:\$PATH\"

# Source ASDF for Zsh
if [[ -f \"\$ASDF_DIR/asdf.sh\" ]]; then
    source \"\$ASDF_DIR/asdf.sh\"
fi

# ASDF completions for Zsh
if [[ -f \"\$ASDF_DIR/completions/asdf.bash\" ]]; then
    source \"\$ASDF_DIR/completions/asdf.bash\"
fi

# Zsh-specific ASDF configuration
fpath=(\$ASDF_DIR/completions \$fpath)
autoload -Uz compinit && compinit"
    
    # Add plugin manager specific configuration
    case $plugin_manager in
        "oh-my-zsh")
            asdf_config+="\n\n# Oh My Zsh ASDF plugin (alternative to manual setup)\n# plugins=(... asdf)"
            ;;
        "prezto")
            asdf_config+="\n\n# Prezto ASDF module\n# Add 'asdf' to modules in ~/.zpreztorc"
            ;;
        "zinit")
            asdf_config+="\n\n# Zinit ASDF plugin\n# zinit load asdf-vm/asdf"
            ;;
    esac
    
    # Check if configuration already exists
    if ! grep -q "ASDF Configuration for Zsh" "$shell_config" 2>/dev/null; then
        echo "$asdf_config" >> "$shell_config"
        print_success "Added ASDF configuration to $(basename "$shell_config")"
    else
        print_warning "ASDF configuration already exists in $(basename "$shell_config")"
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
typeset -gx PYTHONPATH=\"/etc/ssl/certs/ca-certificates.crt\"

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
    print_step "1" "Installing required packages"
    
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
    sudo apt clean && sudo apt autoclean
    sudo rm -rf /var/lib/apt/lists/*
    
    print_substep "Updating package lists..."
    if sudo apt update -y --fix-missing; then
        print_success "Package lists updated"
    else
        print_warning "Package list update failed, continuing..."
    fi
    
    # Install required packages
    print_substep "Installing required packages..."
    local failed_packages=()
    local installed_count=0
    
    for package in "${required_packages[@]}"; do
        show_progress $((++installed_count)) ${#required_packages[@]} "Installing $package"
        
        if sudo apt install -y --fix-missing --fix-broken "$package" &>/dev/null; then
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
        if sudo apt install -y "$package" &>/dev/null; then
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
}

# Enhanced JSON configuration loading with Zsh
load_config_zsh() {
    local config_file="./plugins.json"
    
    print_step "2" "Loading configuration"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Zsh associative arrays (note: Zsh arrays are 1-indexed)
    typeset -gA plugins
    typeset -ga manual_version_plugins
    typeset -gA recommended_versions
    
    print_substep "Loading plugins configuration..."
    
    # Load plugins into associative array
    local plugin_data
    plugin_data=$(jq -r '.plugins | to_entries[] | "\(.key)=\(.value)"' "$config_file")
    
    while IFS='=' read -r key value; do
        plugins[$key]=$value
    done <<< "$plugin_data"
    
    # Load manual version plugins
    local manual_plugins
    manual_plugins=$(jq -r '.special_handling.manual_version[]' "$config_file")
    
    while IFS= read -r plugin; do
        manual_version_plugins+=("$plugin")
    done <<< "$manual_plugins"
    
    # Load recommended versions
    local recommended_data
    recommended_data=$(jq -r '.special_handling.recommended_versions | to_entries[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null)
    
    while IFS='=' read -r key value; do
        recommended_versions[$key]=$value
    done <<< "$recommended_data"
    
    print_success "Configuration loaded: ${#plugins[@]} plugins, ${#manual_version_plugins[@]} manual"
}

# Enhanced certificate setup with Zsh features
setup_certificates_zsh() {
    print_step "3" "Setting up certificates"
    
    local cert_dir="./certs"
    
    if [[ ! -d "$cert_dir" ]]; then
        print_warning "Certificate directory not found: $cert_dir"
        return 0
    fi
    
    # Find certificate files using Zsh glob patterns
    local cert_files=($cert_dir/**/*.(crt|pem|cer))
    
    if [[ ${#cert_files[@]} -eq 0 ]]; then
        print_warning "No certificate files found in $cert_dir"
        return 0
    fi
    
    print_substep "Found ${#cert_files[@]} certificate files"
    
    # Copy certificates to system locations
    print_substep "Installing certificates to system..."
    
    for cert_file in "${cert_files[@]}"; do
        local filename=$(basename "$cert_file")
        print_substep "Installing $filename"
        
        sudo cp "$cert_file" "/usr/local/share/ca-certificates/"
        sudo cp "$cert_file" "/etc/ssl/certs/"
    done
    
    print_substep "Updating certificate store..."
    if sudo update-ca-certificates; then
        print_success "Certificate store updated"
    else
        print_error "Failed to update certificate store"
        return 1
    fi
    
    # Configure certificate environment
    configure_shell_certificates_zsh
    
    print_success "Certificates configured"
}

# Enhanced ASDF installation check with Zsh
check_asdf_zsh() {
    print_step "4" "Checking ASDF installation"
    
    if command -v asdf &>/dev/null; then
        print_success "ASDF is already installed"
        return 0
    fi
    
    print_warning "ASDF not found, installing..."
    
    # Default ASDF installation
    local asdf_version="v0.18.0"
    local asdf_dir="$HOME/.asdf"
    
    print_substep "Cloning ASDF repository..."
    
    if [[ -d "$asdf_dir" ]]; then
        print_substep "Updating existing ASDF installation..."
        cd "$asdf_dir"
        git fetch --all
        git checkout "$asdf_version"
        cd - >/dev/null
    else
        if git clone https://github.com/asdf-vm/asdf.git "$asdf_dir" --branch "$asdf_version"; then
            print_success "ASDF cloned successfully"
        else
            print_error "Failed to clone ASDF"
            return 1
        fi
    fi
    
    # Configure ASDF in shell
    configure_asdf_zsh
    
    # Source ASDF for current session
    export ASDF_DIR="$asdf_dir"
    export PATH="$ASDF_DIR/bin:$ASDF_DIR/shims:$PATH"
    source "$ASDF_DIR/asdf.sh"
    
    print_success "ASDF installed and configured"
}

# Enhanced plugin addition with Zsh progress tracking
add_plugin_zsh() {
    local plugin_name=$1
    local plugin_url=$2
    
    print_substep "Adding plugin: $plugin_name"
    
    # Check if plugin already exists
    if asdf plugin list | grep -q "^$plugin_name$"; then
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
        
        # Show available versions
        print_info "Available versions for $plugin_name:"
        for i in {1..${#versions[@]}}; do
            print "  $i) ${versions[$i]}"
        done
        
        # Get recommended version if available
        if [[ -n "${recommended_versions[$plugin_name]}" ]]; then
            print_info "Recommended version: ${recommended_versions[$plugin_name]}"
            print -n "Press Enter for recommended version, or select number: "
            read -r choice
            
            if [[ -z "$choice" ]]; then
                version="${recommended_versions[$plugin_name]}"
            elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#versions[@]} ]]; then
                version="${versions[$choice]}"
            else
                print_error "Invalid selection"
                return 1
            fi
        else
            print -n "Select version (1-${#versions[@]}): "
            read -r choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#versions[@]} ]]; then
                version="${versions[$choice]}"
            else
                print_error "Invalid selection"
                return 1
            fi
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
    if asdf install "$plugin_name" "$version"; then
        print_success "Installed $plugin_name $version"
        
        # Set global version
        if asdf global "$plugin_name" "$version"; then
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
    print_step "7" "Configuring tools with certificates"
    
    local tools_config=(
        "npm:npm config set cafile /etc/ssl/certs/ca-certificates.crt"
        "npm:npm config set strict-ssl true"
        "git:git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt"
        "git:git config --global http.sslVerify true"
        "cargo:mkdir -p ~/.cargo"
        "cargo:echo '[http]\\ncainfo = \"/etc/ssl/certs/ca-certificates.crt\"' > ~/.cargo/config.toml"
        "pip:mkdir -p ~/.config/pip"
        "pip:echo '[global]\\ncert = /etc/ssl/certs/ca-certificates.crt' > ~/.config/pip/pip.conf"
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
    
    # Execute main steps
    setup_certificates_zsh
    install_required_packages_zsh
    load_config_zsh
    check_asdf_zsh
    
    # Install plugins and languages
    print_step "5" "Adding ASDF plugins"
    
    local failed_plugins=()
    local plugin_count=0
    
    for plugin_name in "${(@k)plugins}"; do
        show_progress $((++plugin_count)) ${#plugins[@]} "Processing plugins"
        
        if ! add_plugin_zsh "$plugin_name" "${plugins[$plugin_name]}"; then
            failed_plugins+=("$plugin_name")
        fi
    done
    
    print_step "6" "Installing language versions"
    
    local failed_installs=()
    local install_count=0
    
    for plugin_name in "${(@k)plugins}"; do
        if [[ ! " ${failed_plugins[*]} " =~ " $plugin_name " ]]; then
            show_progress $((++install_count)) $((${#plugins[@]} - ${#failed_plugins[@]})) "Installing versions"
            
            if ! install_latest_zsh "$plugin_name"; then
                failed_installs+=("$plugin_name")
            fi
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

# Execute main function
main_zsh "$@"