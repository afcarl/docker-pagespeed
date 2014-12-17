##
# Custom Nginx build with SPDY 2 & mod_pagespeed support
#
##
FROM ubuntu:14.10
MAINTAINER Frank Lemanschik <frank@dspeed.eu>
ENV NGINX_VERSION 1.6.0
ENV PAGESPEED_VERSION 1.7.30.4-beta.zip
ENV MODULESDIR /usr/src/nginx-modules
ENV DEBIAN_FRONTEND noninteractive

# Dependencys
RUN echo "deb http://archive.ubuntu.com/ubuntu utopic main restricted universe \n\
deb-src http://archive.ubuntu.com/ubuntu utoppic main restricted universe\n\
deb http://archive.ubuntu.com/ubuntu utopic-updates main restricted universe\n\
deb-src http://archive.ubuntu.com/ubuntu utopic-updates main restricted universe\n" > /etc/apt/sources.list \
 && locale-gen en_US.UTF-8 \
 && dpkg-reconfigure locales \
 && apt-key adv --fetch-keys http://nginx.org/keys/nginx_signing.key \
 && echo "deb-src http://nginx.org/packages/ubuntu/ utopic nginx" > /etc/apt/sources.list.d/nginx-src.list \
 && apt-get update \
 && apt-get build-dep nginx-full -y \
 && apt-get install -yq \
  nano \
  vim \
  git \
  lynx \
  curl \
  wget \
  build-essential \
  zlib1g-dev \
  libpcre3 \
  libpcre3-dev \
  unzip  \
 && apt-get clean -y \
 && apt-get clean all \
 && rm -rf /var/lib/apt/lists/*
 && mkdir ${MODULESDIR} \
 && cd ${MODULESDIR} \
 && wget --no-check-certificate https://github.com/pagespeed/ngx_pagespeed/archive/v${PAGESPEED_VERSION}.zip \
 && unzip v${PAGESPEED_VERSION}.zip \
 && cd ngx_pagespeed-${PAGESPEED_VERSION}/ \
 && wget --no-check-certificate https://dl.google.com/dl/page-speed/psol/1.7.30.4.tar.gz \
 && tar -xzvf 1.7.30.4.tar.gz \
 && cd /usr/src/ \
 && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
 && tar xf nginx-${NGINX_VERSION}.tar.gz \
 && rm -f nginx-${NGINX_VERSION}.tar.gz

# Compile nginx
RUN cd /usr/src/nginx-${NGINX_VERSION} \ 
 && ./configure \
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
	--add-module=${MODULESDIR}/ngx_pagespeed${PAGESPEED_VERSION}- \
 && cd /usr/src/nginx-${NGINX_VERSION} \
 && make \
 && make install \
 && mkdir -p /var/cache/tmp && chmod 777 /var/cache/tmp \
 && mkdir -p /var/cache/nginx && chmod 777 /var/cache/nginx \
 && mkdir -p /var/cache/pagespeed && chmod 777 /var/cache/pagespeed 
ADD nginx /etc/nginx/
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# VOLUME /etc/nginx/sites-enabled
# VOLUME /var/run/gunicorn
# VOLUME /var/log/nginx
# VOLUME /var/www/static
# VOLUME /var/www/media

EXPOSE 80
CMD ["nginx"]
