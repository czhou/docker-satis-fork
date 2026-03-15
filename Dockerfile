ARG BUILD_FROM=debian:bullseye-slim
FROM $BUILD_FROM

LABEL maintainer="Yannick Pereira-Reis <yannick.pereira.reis@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

# 设置系统
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 切换到国内源并安装必须的软件包
RUN sed -i 's#http://deb.debian.org#http://mirrors.163.com#g' /etc/apt/sources.list
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        software-properties-common \
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
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
        && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/php.list \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
        php8.3 \
        php8.3-tidy \
        php8.3-cli \
        php8.3-common \
        php8.3-curl \
        php8.3-intl \
        php8.3-fpm \
        php8.3-zip \
        php8.3-apcu \
        php8.3-xml \
        php8.3-mbstring \
	&& apt-get clean \
    && rm -Rf /var/lib/apt/lists/* /usr/share/man/* /usr/share/doc/* /tmp/* /var/tmp/*

RUN sed -i "s/;date.timezone =.*/date.timezone = Asia\/Shanghai/" /etc/php/8.3/cli/php.ini \
	&& sed -i "s/;date.timezone =.*/date.timezone = Asia\/Shanghai/" /etc/php/8.3/fpm/php.ini \
	&& echo "daemon off;" >> /etc/nginx/nginx.conf \
	&& sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/8.3/fpm/php-fpm.conf \
	&& sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.3/fpm/php.ini \
	&& sed -i "s/;decorate_workers_output/decorate_workers_output/" /etc/php/8.3/fpm/pool.d/www.conf \
	&& sed -i "s/;clear_env/clear_env/" /etc/php/8.3/fpm/pool.d/www.conf

ADD nginx/default   /etc/nginx/sites-available/default
ADD nginx/default   /etc/nginx/sites-available/default

# Install ssh key
ENV USER_HOME=/var/www
RUN mkdir -p $USER_HOME/.ssh/ && touch $USER_HOME/.ssh/known_hosts

ADD scripts /app/scripts
# Install Composer, satis and satisfy
ENV COMPOSER_HOME=/var/www/.composer
RUN chmod +x /app/scripts/composer_install.sh \
    && /app/scripts/composer_install.sh \
    && composer self-update \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    && composer config --global audit.block-insecure false

#############################################################################################"
##
## Install from dist
##
#ADD https://github.com/ludofleury/satisfy/archive/3.4.0.zip /
#RUN unzip 3.4.0.zip \
#    && mv /satisfy-3.4.0 /satisfy \
#    && rm -rf 3.4.0.zip

##
##
## Install from composer/packagist
RUN composer create-project composer/satis /satisfy dev-main --no-dev -n --no-scripts --no-plugins

##
## Install from git clone
##
#RUN git clone https://github.com/ludofleury/satisfy.git
#############################################################################################"


RUN chmod -R 777 /satisfy

ADD scripts/crontab /etc/cron.d/satis-cron
ADD config/ /satisfy/config_tmp

RUN chmod 0644 /etc/cron.d/satis-cron \
	&& touch /var/log/satis-cron.log \
	&& chmod +x /app/scripts/startup.sh

ADD supervisor/0-install.conf /etc/supervisor/conf.d/0-install.conf
ADD supervisor/1-cron.conf /etc/supervisor/conf.d/1-cron.conf
ADD supervisor/2-nginx.conf /etc/supervisor/conf.d/2-nginx.conf
ADD supervisor/3-php.conf /etc/supervisor/conf.d/3-php.conf

ENV APP_ENV=prod
ENV APP_DEBUG=0
RUN mkdir -p /run/php && touch /run/php/php8.3-fpm.sock && touch /run/php/php8.3-fpm.pid

WORKDIR /app

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

EXPOSE 80
EXPOSE 443

