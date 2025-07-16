# Dotfiles PKI Setup

Tự động cài đặt và cấu hình môi trường phát triển với hỗ trợ PKI certificates trên Windows và WSL2.

## Tính năng

- **PKI Certificate Management**: Tự động cài đặt certificates cho Windows và Linux
- **WSL2 Setup**: Cài đặt và cấu hình WSL2 với Kali Linux
- **Font Installation**: Cài đặt fonts FiraCode và FiraMono
- **Development Environment**: Tự động cài đặt 19+ ngôn ngữ lập trình qua ASDF
- **Container Support**: Cài đặt Docker và Podman

## Cấu trúc Project

```
dotfiles_pki/
├── certs/              # PKI certificates (*.cer, *.crt, *.pem)
├── fonts/              # Font files (FiraCode.zip, FiraMono.zip)
├── wsl/
│   └── .wslconfig      # WSL2 configuration
├── index.ps1           # Windows setup script
├── index.sh            # Linux setup script
└── README.md           # Documentation
```

## Yêu cầu

### Windows
- Windows 10/11 với quyền Administrator
- PowerShell 5.1+

### Linux (WSL2)
- Kali Linux distribution
- Internet connection

## Cài đặt

### 1. Chạy trên Windows

```powershell
# Chạy với quyền Administrator
.\index.ps1
```

Script sẽ thực hiện:
1. Cài đặt PKI certificates vào Trusted Root Store
2. Cài đặt fonts từ thư mục `fonts/`
3. Cài đặt/cập nhật WSL2
4. Cài đặt Kali Linux distribution
5. Cấu hình WSL2 với file `.wslconfig`
6. Chạy script Linux setup

### 2. Chạy trên Linux (WSL2)

```bash
# Tự động chạy từ Windows script hoặc chạy thủ công
bash index.sh
```

Script sẽ thực hiện:
1. Cài đặt certificates vào Linux certificate store
2. Cài đặt Docker và Podman
3. Cài đặt ASDF version manager
4. Cài đặt 19+ ngôn ngữ lập trình
5. Cấu hình SSL certificates cho tất cả tools

## Ngôn ngữ được hỗ trợ

| Ngôn ngữ | Plugin | Mô tả |
|----------|--------|-------|
| CMake | cmake | Build system |
| Bun | bun | JavaScript runtime |
| Node.js | nodejs | JavaScript runtime |
| Deno | deno | JavaScript/TypeScript runtime |
| Rust | rust | Systems programming |
| Zig | zig | Systems programming |
| OCaml | ocaml | Functional programming |
| Go | golang | Systems programming |
| Python | python/uv | General purpose |
| Haskell | haskell | Functional programming |
| Erlang/Elixir | erlang/elixir | Concurrent programming |
| Flutter | flutter | Mobile development |
| Java | java | Enterprise development |
| Lua | lua | Scripting |
| PureScript | purescript | Functional web programming |
| V | v | Systems programming |
| Gleam | gleam | Type-safe functional programming |

## Cấu hình

### WSL2 Configuration
File `wsl/.wslconfig` cấu hình:
- Memory: 24GB RAM
- Processors: 6 CPU cores  
- Swap: 100GB
- Networking: Mirrored mode

### Certificate Configuration
Certificates được cài đặt tự động vào:
- **Windows**: Trusted Root Certificate Store
- **Linux**: `/etc/ssl/certs/` và `/usr/local/share/ca-certificates/`

### SSL Environment Variables
```bash
export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
export SSL_CERT_DIR="/etc/ssl/certs"
export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"
export CURL_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"
export BUN_CA_BUNDLE_PATH="/etc/ssl/certs/ca-certificates.crt"
export DENO_CERT="/etc/ssl/certs/ca-certificates.crt"
```

## Sử dụng

### Kiểm tra cài đặt
```bash
# Xem các ngôn ngữ đã cài đặt
asdf list

# Xem phiên bản hiện tại
asdf current

# Kiểm tra Docker
docker --version
podman --version
```

### Quản lý phiên bản
```bash
# Cài đặt phiên bản cụ thể
asdf install nodejs 18.17.0

# Đặt phiên bản global
asdf global nodejs 18.17.0

# Đặt phiên bản local cho project
asdf local python 3.11.0
```

## Troubleshooting

### Certificate Issues
- Kiểm tra certificates trong `/etc/ssl/certs/`
- Chạy `sudo update-ca-certificates`
- Restart terminal để áp dụng environment variables

### ASDF Issues
- Chạy `source ~/.bashrc` hoặc `source ~/.zshrc`
- Kiểm tra `asdf --version`
- Xem log chi tiết khi cài đặt

### WSL2 Issues
- Restart WSL: `wsl --shutdown` và `wsl`
- Kiểm tra WSL version: `wsl --version`
- Update WSL: `wsl --update`

## Tùy chỉnh

### Thêm certificates
1. Đặt file certificate vào thư mục `certs/`
2. Chạy lại script setup

### Thêm fonts
1. Đặt file .zip chứa fonts vào thư mục `fonts/`
2. Chạy lại Windows script

### Thay đổi cấu hình WSL2
Chỉnh sửa file `wsl/.wslconfig` theo nhu cầu.

## License

MIT License