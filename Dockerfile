FROM php:7.1

# build user
RUN useradd --create-home --system build
ENV PATH "$PATH:/app/bin:/home/build/bin"

# install all the things
RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends \
  && echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends \
  && apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get -s dist-upgrade | grep "^Inst" | \
       grep -i securi | awk -F " " '{print $2}' | \
       xargs apt-get -qq -y --no-install-recommends install \
  # apt \
  && DEBIAN_FRONTEND=noninteractive apt-get -qq -y --no-install-recommends install \
     \
     apt-transport-https \
     ca-certificates \
     bzip2 \
     curl \
     git \
     libfreetype6-dev \
     libjpeg-dev \
     libpng-dev \
     libmcrypt-dev \
     libxslt1-dev \
     make \
     mysql-client \
     nano \
     net-tools \
     openssh-client \
     patch \
     procps \
     redis-tools \
     rsync \
     supervisor \
     unzip \
     wget \
  # php \
  && docker-php-ext-install mcrypt \
  && docker-php-ext-install xsl \
  && docker-php-ext-install intl \
  && docker-php-ext-configure gd \
    --with-jpeg-dir=/usr/include/ \
    --with-freetype-dir=/usr/include/ \
    && docker-php-ext-install gd \
  && docker-php-ext-install pdo_mysql \
  && docker-php-ext-install soap \
  && docker-php-ext-install zip \
  && docker-php-ext-install bcmath

# tool: composer
# --------------
RUN curl -s -f -L -o /tmp/installer.php https://raw.githubusercontent.com/composer/getcomposer.org/b107d959a5924af895807021fcef4ffec5a76aa9/web/installer \
 && php -r " \
    \$signature = '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061'; \
    \$hash = hash('SHA384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
        unlink('/tmp/installer.php'); \
        echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
        exit(1); \
    }" \
 && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer

# tool: composer > hirak/prestissimo
# ----------------------------------
# enabled parallel downloading of composer depedencies and massively speeds up the
# time it takes to run composer install.
USER build
RUN composer global require hirak/prestissimo
USER root

# tool: confd
# allows the templatising of configuration files using various key value backends.
RUN curl -sSL -o /usr/local/bin/confd \
    https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 \
 && chmod +x /usr/local/bin/confd

# clean
RUN apt-get auto-remove -qq -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# start!
WORKDIR /app
ENTRYPOINT ["/entrypoint.sh"]
