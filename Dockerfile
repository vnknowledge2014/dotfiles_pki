# Simple PKI Development Environment
# Configurable via build arguments
ARG BASE_IMAGE=debian:bookworm-slim
FROM ${BASE_IMAGE}

# Configure certificates and base system
RUN if [ -f /etc/alpine-release ]; then \
        apk add --no-cache ca-certificates curl wget git build-base unzip bash sudo python3 py3-pip; \
    else \
        apt-get update && apt-get install -y ca-certificates curl wget git build-essential unzip sudo python3 python3-pip && rm -rf /var/lib/apt/lists/*; \
    fi

# Create non-root user
RUN if [ -f /etc/alpine-release ]; then \
        adduser -D -s /bin/bash devuser && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    else \
        useradd -m -s /bin/bash devuser && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    fi

# Copy and install certificates
COPY certs/ /usr/local/share/ca-certificates/
COPY certs/ /etc/ssl/certs/
RUN update-ca-certificates

# Set certificate environment variables
ENV SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
ENV SSL_CERT_DIR="/etc/ssl/certs"
ENV REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"
ENV CURL_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"

# Install ASDF for language management
USER devuser
WORKDIR /home/devuser
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.18.0 && \
    echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc && \
    echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc && \
    echo 'export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"' >> ~/.bashrc && \
    echo 'export SSL_CERT_DIR="/etc/ssl/certs"' >> ~/.bashrc && \
    echo 'export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"' >> ~/.bashrc && \
    echo 'export CURL_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"' >> ~/.bashrc

# Language build arguments
ARG INSTALL_NODEJS=false
ARG INSTALL_PYTHON=false
ARG INSTALL_GOLANG=false
ARG INSTALL_RUST=false
ARG INSTALL_JAVA=false

# Install languages conditionally
ENV PATH="/home/devuser/.asdf/bin:/home/devuser/.asdf/shims:$PATH"

# Node.js
RUN if [ "$INSTALL_NODEJS" = "true" ]; then \
        bash -c 'source ~/.bashrc && \
        asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git && \
        asdf install nodejs latest && \
        asdf global nodejs latest && \
        npm config set cafile /etc/ssl/certs/ca-certificates.crt'; \
    fi

# Python
RUN if [ "$INSTALL_PYTHON" = "true" ]; then \
        bash -c 'source ~/.bashrc && \
        asdf plugin add python https://github.com/asdf-community/asdf-python.git && \
        asdf install python latest && \
        asdf global python latest && \
        mkdir -p ~/.config/pip && \
        echo "[global]\ncert = /etc/ssl/certs/ca-certificates.crt" > ~/.config/pip/pip.conf'; \
    fi

# Go
RUN if [ "$INSTALL_GOLANG" = "true" ]; then \
        bash -c 'source ~/.bashrc && \
        asdf plugin add golang https://github.com/asdf-community/asdf-golang.git && \
        asdf install golang latest && \
        asdf global golang latest'; \
    fi

# Rust
RUN if [ "$INSTALL_RUST" = "true" ]; then \
        bash -c 'source ~/.bashrc && \
        asdf plugin add rust https://github.com/asdf-community/asdf-rust.git && \
        asdf install rust latest && \
        asdf global rust latest && \
        mkdir -p ~/.cargo && \
        echo "[http]\ncainfo = \"/etc/ssl/certs/ca-certificates.crt\"" > ~/.cargo/config.toml'; \
    fi

# Java
RUN if [ "$INSTALL_JAVA" = "true" ]; then \
        bash -c 'source ~/.bashrc && \
        asdf plugin add java https://github.com/halcyon/asdf-java.git && \
        asdf install java latest && \
        asdf global java latest'; \
    fi

# Configure Git
RUN git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt

EXPOSE 3000 8080
CMD ["/bin/bash"]