FROM daocloud.io/library/debian:stretch-slim

ENV DEBIAN_FRONTEND noninteractive
ENV TIMEZONE Asia/Shanghai
ENV GIT_SSL_NO_VERIFY true

# replace sources.list
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        software-properties-common \
        vim \
        cron \
        nano \
        wget \
        sudo \
        lsb-release \
        apt-transport-https \
        git \
        curl \
        supervisor \
        nginx \
        ssh \
        unzip \
        libmcrypt-dev \
        cmake \
        g++ \
        pkg-config \
        libwebsockets-dev \
        libjson-c-dev \
        libssl-dev\
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
        && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/php.list \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
        php7.3 \
        php7.3-tidy \
        php7.3-cli \
        php7.3-common \
        php7.3-curl \
        php7.3-intl \
        php7.3-fpm \
        php7.3-zip \
        php7.3-apcu \
        php7.3-xml \
        php7.3-mbstring \
	&& apt-get clean \
    && rm -Rf /var/lib/apt/lists/* /usr/share/man/* /usr/share/doc/* /tmp/* /var/tmp/*

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.3/cli/php.ini \
	&& sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.3/fpm/php.ini \
	&& echo "daemon off;" >> /etc/nginx/nginx.conf \
	&& sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.3/fpm/php-fpm.conf \
	&& sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.3/fpm/php.ini

# Install ssh key
ENV USER_HOME /var/www

RUN mkdir -p $USER_HOME/.ssh/ && touch $USER_HOME/.ssh/known_hosts \
    && mkdir -p /app \
    && mkdir -p /tmp/.composer/ \
    && chmod -R 777 /tmp/.composer/

ADD nginx/default   /etc/nginx/sites-available/default

# 复制宿主机从的文件con
ADD config/composer_config.json /tmp/.composer/composer.json

# Install Composer, satis and satisfy
ENV COMPOSER_HOME /tmp/.composer
COPY --from=composer:1.9.0 /usr/bin/composer /usr/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    && git config --global http.postBuffer 2000000000 \
    && git config --global http.sslVerify false \
    && composer global require hirak/prestissimo -vvv \
    && git clone --depth 1 -v https://gitee.com/src-github/ludofleury-satisfy.git /satisfy \
    && wget --no-check-certificate https://github.com/tsl0922/ttyd/releases/download/1.5.2/ttyd_linux.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd \
    && cd /satisfy \
    && composer install -vvv \
    && chmod -R 777 /satisfy

ADD supervisor/4-ttyd.conf /etc/supervisor/conf.d/4-ttyd.conf

WORKDIR /app

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

EXPOSE 80
EXPOSE 443
EXPOSE 7681
