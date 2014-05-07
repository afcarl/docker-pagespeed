##
# Custom Nginx build with SPDY 2 & mod_pagespeed support
#
# Adapted from https://github.com/strogonoff/docker-pagespeed
# Adapted from https://github.com/laurisvan/docker-pagespeed
# Adapted from https://index.docker.io/u/gvangool/nginx-src/
#
##

FROM ubuntu:trusty
MAINTAINER Alan Blount <alan@zeroasterisk.com>
ENV NGINX_VERSION 1.6.0
ENV OPENSSL_VERSION 1.0.1g
ENV PAGESPEED_VERSION 1.7.30.4-beta.zip

# Set the env variable DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND noninteractive

# Fix locales
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

# Enable universe & src repo's
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main restricted universe\ndeb-src http://archive.ubuntu.com/ubuntu trusty main restricted universe\ndeb http://archive.ubuntu.com/ubuntu trusty-updates main restricted universe\ndeb-src http://archive.ubuntu.com/ubuntu trusty-updates main restricted universe\n" > /etc/apt/sources.list

# Install build tools for nginx
RUN apt-get update && apt-get build-dep nginx-full -y && apt-get install wget -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add Nginx source repository & signing key
#RUN echo "deb http://nginx.org/packages/ubuntu/ trusty nginx" >> /etc/apt/sources.list.d/nginx-trusty.list
RUN apt-key adv --fetch-keys http://nginx.org/keys/nginx_signing.key
RUN echo "deb-src http://nginx.org/packages/ubuntu/ trusty nginx" >> /etc/apt/sources.list.d/nginx-trusty.list

# Add pico; we'll do some local mods anyway
RUN apt-get update &&  apt-get install nano vim -y

# Install Nginx from a tarball
# Install build tools for nginx
ENV MODULESDIR /usr/src/nginx-modules
RUN cd /usr/src/ && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar xf nginx-${NGINX_VERSION}.tar.gz && rm -f nginx-${NGINX_VERSION}.tar.gz

# Force OpenSSL 1.0.1
RUN cd /usr/src && wget http://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && tar xvzf openssl-${OPENSSL_VERSION}.tar.gz

# Install additional modules
RUN apt-get update && apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev unzip
RUN mkdir ${MODULESDIR}
RUN cd ${MODULESDIR} && \
	wget --no-check-certificate https://github.com/pagespeed/ngx_pagespeed/archive/v${PAGESPEED_VERSION}.zip && \
	unzip v${PAGESPEED_VERSION}.zip && \
	cd ngx_pagespeed-${PAGESPEED_VERSION}/ && \
	wget --no-check-certificate https://dl.google.com/dl/page-speed/psol/1.7.30.4.tar.gz && \
	tar -xzvf 1.7.30.4.tar.gz

# Compile nginx
RUN cd /usr/src/nginx-${NGINX_VERSION} && ./configure \
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-file-aio \
	--with-http_spdy_module \
	--with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Wformat-security -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
	--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
	--with-ipv6 \
	--with-sha1=/usr/include/openssl \
 	--with-md5=/usr/include/openssl \
	--with-openssl="../openssl-${OPENSSL_VERSION}" \
	--add-module=${MODULESDIR}/ngx_pagespeed${PAGESPEED_VERSION}-

RUN cd /usr/src/nginx-${NGINX_VERSION} && make && make install

ADD nginx /etc/nginx/

VOLUME /etc/nginx/sites-enabled
VOLUME /var/run/gunicorn
VOLUME /var/log/nginx
VOLUME /var/www/static
VOLUME /var/www/media


# generic tmp cahce
RUN mkdir -p /var/cache/tmp && chmod 777 /var/cache/tmp

# nginx proxy_cache_dir
RUN mkdir -p /var/cache/nginx && chmod 777 /var/cache/nginx

# pagespeed proxy_cache_dir
RUN mkdir -p /var/cache/pagespeed && chmod 777 /var/cache/pagespeed

# Turn off nginx starting as a daemon
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Purge APT cache
RUN apt-get clean all

EXPOSE 80
CMD ["nginx"]
