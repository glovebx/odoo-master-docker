FROM arm64v8/debian:bullseye-slim
MAINTAINER Odoo S.A. <info@odoo.com>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Create work folder
RUN mkdir /work/
WORKDIR /work/

# Update python version
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-get update && \
    apt install -y python3.9

# Install vim
RUN apt-get update && \
    apt-get install -y vim

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-geoip2 \
        python3-decorator \
        python3-docutils \
        python3-idna \
        python3-jinja2 \
        python3-libsass \
        python3-mock \
        python3-gevent \
        python3-greenlet \
        python3-psycopg2 \
        python3-num2words \
        python3-ofxparse \
        python3-passlib \
        python3-pdfminer \
        python3-pillow \
        python3-pip \
        python3-phonenumbers \
        python3-polib \
        python3-psutil \
        python3-pydot \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        python3-xlsxwriter \
        python3-pypdf2 \
        python3-dateutil \
        python3-stdnum \
        python3-reportlab \
        python3-requests \
        python3-zeep \
        python3-vobject \
        python3-werkzeug \        
        xz-utils \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_arm64.deb \
    && echo '43d0db99ab0e6b5f60b465a49c764c50d6b31337 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Pip install dependencies
RUN pip3 install pyopenssl==22.1.0
RUN pip3 install cryptography
RUN pip3 install babel
RUN pip3 install pyserial
RUN pip3 install pytz
RUN pip3 install pyusb
RUN pip3 install -U debugpy

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Create default user
RUN useradd -ms /bin/bash odoo

# Copy source files
COPY ./odoo/ /work/odoo/

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and Mount /work for source files and /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN chown -R odoo /work/odoo \
    && chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons \
    && mkdir -p /var/lib/odoo \
    && chown -R odoo /var/lib/odoo
VOLUME ["/work", "/var/lib/odoo", "/mnt/extra-addons"]

COPY ./psycopg2/ /mnt/extra-addons/psycopg2/
RUN chown -R odoo /mnt/extra-addons

# Expose Odoo services
# 3000 for debug
EXPOSE 8069 8071 8072 3000

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]