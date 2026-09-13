# ============================================================================
# ESP-IDF base image
# ============================================================================
ARG DOCKER_IDF_VERSION=v6.1

FROM espressif/idf:${DOCKER_IDF_VERSION}
ARG DOCKER_IDF_VERSION
ENV DEVCONTAINER_IDF_VERSION=${DOCKER_IDF_VERSION}


# ============================================================================
# Build configuration
# ============================================================================
ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=ubuntu

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8


# ============================================================================
# ccache
# ============================================================================
ARG ENABLE_CCACHE=1
ARG CCACHE_MAXSIZE=5G

ENV IDF_CCACHE_ENABLE=${ENABLE_CCACHE}
ENV CCACHE_DIR=/home/${USERNAME}/.cache/ccache
ENV CCACHE_MAXSIZE=${CCACHE_MAXSIZE}


# ============================================================================
# Development dependencies
# ============================================================================
# As dependencias utilizadas pelo template sao instaladas explicitamente,
# mesmo quando algumas delas ja existem na imagem base.
RUN apt-get update --quiet \
    && apt-get install -y --no-install-recommends --quiet \
        binwalk \
        ca-certificates \
        ccache \
        clang-format \
        clang-tidy \
        cppcheck \
        curl \
        fd-find \
        file \
        git \
        iproute2 \
        jq \
        less \
        lsof \
        nano \
        net-tools \
        openssh-client \
        picocom \
        pre-commit \
        procps \
        ripgrep \
        sudo \
        tree \
        udev \
        usbutils \
        wget \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/*


# ============================================================================
# Command compatibility
# ============================================================================
# Debian/Ubuntu instala fd-find com o executavel "fdfind".
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd


# ============================================================================
# Development user
# ============================================================================
# Algumas imagens do ESP-IDF ja possuem o usuario "ubuntu".
# Caso ele nao exista, cria o usuario.
RUN set -eux; \
    if ! id -u "${USERNAME}" >/dev/null 2>&1; then \
        if ! getent group "${USERNAME}" >/dev/null 2>&1; then \
            groupadd "${USERNAME}"; \
        fi; \
        useradd \
            --create-home \
            --gid "${USERNAME}" \
            --shell /bin/bash \
            "${USERNAME}"; \
    fi


# ============================================================================
# User permissions
# ============================================================================
# Garante que o grupo dialout exista e permite acesso a portas seriais
# como /dev/ttyUSB* e /dev/ttyACM*.
RUN getent group dialout >/dev/null 2>&1 \
        || groupadd --system dialout \
    && usermod -aG dialout "${USERNAME}"

# Permite executar tarefas administrativas pontuais sem senha.
RUN printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${USERNAME}" \
        > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"


# ============================================================================
# ccache storage
# ============================================================================
RUN mkdir -p "${CCACHE_DIR}" \
    && chown -R "${USERNAME}:" "/home/${USERNAME}"


# ============================================================================
# Git
# ============================================================================
# Pode ser habilitado caso necessario para repositorios montados.
# Nao habilitamos por padrao porque '*' marca qualquer repositorio como seguro.
#
# RUN git config --system --add safe.directory '*'


# ============================================================================
# Workspace
# ============================================================================
RUN mkdir -p /app \
    && chown "${USERNAME}:" /app

WORKDIR /app


# ============================================================================
# Runtime
# ============================================================================
USER ${USERNAME}
