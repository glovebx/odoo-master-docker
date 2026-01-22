FROM arm64v8/debian:bookworm
LABEL glovebx=<1069010@qq.com>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG=C.UTF-8

# Create work folder
RUN mkdir /work/
WORKDIR /work/

# 1. 安装编译所需的依赖项
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    gnupg \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libldap2-dev \
    libsasl2-dev \    
    libssl-dev \    
    libreadline-dev \
    libffi-dev \
    libsqlite3-dev \
    libbz2-dev \
    liblzma-dev \
    # 解决可能出现的 _dbm 模块缺失问题 [8](@ref)
    libgdbm-compat-dev \
    libdb-dev \
    libpq-dev \
    python3-dev \
    gcc \
    make && \
    # 清理缓存以减小镜像体积
    rm -rf /var/lib/apt/lists/*

# 2. 下载 Python 3.12 源码并编译 [1,2,3](@ref)
WORKDIR /tmp
# 请访问 https://www.python.org/downloads/ 确认3.12的最新小版本号
RUN curl -fsSL https://www.python.org/ftp/python/3.12.6/Python-3.12.6.tgz -o Python-3.12.6.tgz && \
    tar -xzf Python-3.12.6.tgz && \
    cd Python-3.12.6 && \
    # 启用优化，虽然编译慢一些，但性能更好 [4](@ref)
    ./configure --enable-optimizations && \
    make -j $(nproc) && \
    make altinstall && \
    # 编译安装后清理源码，减小镜像体积
    cd /tmp && \
    rm -rf Python-3.12.6*

# 3. 验证安装
RUN python3.12 --version && pip3.12 --version

# 4. 创建符号链接，替换系统默认命令
# 备份原有链接（如果存在且非链接文件，则跳过备份）
RUN cd /usr/bin && \
    ( [ -L python3 ] && mv python3 python3.bak || true ) && \
    ln -sf /usr/local/bin/python3.12 python3

RUN cd /usr/bin && \
    ( [ -L pip3 ] && mv pip3 pip3.bak || true ) && \
    ln -sf /usr/local/bin/pip3.12 pip3

# 可选：如果希望 `python` 命令也指向 Python 3.12
RUN cd /usr/bin && \
    ln -sf /usr/local/bin/python3.12 python

# 5. 验证默认版本是否已切换
RUN python3 --version && pip3 --version && python --version

RUN pip3.12 install --upgrade pip

# Install vim
RUN apt-get update && \
    apt-get install -y vim

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        cargo \
        dirmngr \
        fonts-noto-cjk \
        fonts-courier-prime \
        node-less \
        npm \
        pkg-config \        
        xz-utils \
        openssl \
        libc6 \
        libfreetype6 \
        libjpeg62-turbo \
        libpng16-16 \
        libssl3 \
        libstdc++6 \
        libx11-6 \
        libxcb1 \
        libxext6 \
        libxrender1 \
        zlib1g \
        unzip 

RUN curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_arm64.deb \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# 添加 PostgreSQL 官方 APT 仓库的 GPG 密钥和源
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg
# 下面的命令会自动获取系统代号（如 "bookworm"）
RUN echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# 更新并安装 PostgreSQL 客户端-16
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client-16 \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Create default user
RUN useradd -ms /bin/bash odoo

# Copy source files
COPY ./odoo/ /work/odoo/

RUN pip3.12 install -r /work/odoo/requirements.txt

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and Mount /work for source files and /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN chown -R odoo /work/odoo \
    && chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons \
    && mkdir -p /mnt/dev-addons \
    && chown -R odoo /mnt/dev-addons \
    && mkdir -p /var/lib/odoo \
    && chown -R odoo /var/lib/odoo
VOLUME ["/work", "/var/lib/odoo", "/mnt/extra-addons", "/mnt/dev-addons"]

COPY ./psycopg2/ /mnt/extra-addons/psycopg2/
RUN chown -R odoo /mnt/extra-addons

# Expose Odoo services
# 3000 for debug
EXPOSE 8069 8071 8072 3000

# Set the default config file
ENV ODOO_RC=/etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]