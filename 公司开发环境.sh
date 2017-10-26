#!/bin/bash
#php开发环境安装指南
cd ~
#src为软件安装目录,targz为源代码的安装包下载目录,projects为项目目录
mkdir src,projects
#1.Mac依赖安装   安装brew(Mac机的包管理工具)
xcode-select --install
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#安装wget
brew install wget
#安装依赖
brew install  readline libmcrypt freetype libpng jpeg mcrypt mhash openssl re2c ImageMagick bison autoconf ffmpeg ImageMagick pcre zlib
#安装nginx
mkdir ~/src/nginx
wget http://nginx.org/download/nginx-1.8.0.tar.gz
tar -zxvf nginx-1.8.0.tar.gz
cd nginx-1.8.0
./configure --prefix=~/src/nginx/ --with-http_ssl_module --with-ld-opt="-L/usr/local/opt/openssl/lib" --with-cc-opt="-I/usr/local/opt/openssl/include"
make
sudo make install

配置php-fastcgi
  vi /usr/local/nginx/conf/nginx.conf
  server {
      listen 80;
      # 项目域名,需要同步改/etc/hosts
      server_name money.com;
      # 配置为项目路径public目录
      root /Users/apple/projects/money_php/public;
      index index.php index.html;
      try_files $uri @rewrite;

      location @rewrite {
           rewrite ^/(.*)$ /index.php?_url=/$1;
      }

      location ~ \.php {
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                # 最长执行时间
                fastcgi_read_timeout 300;
                fastcgi_split_path_info       ^(.+\.php)(/.+)$;
                fastcgi_param PATH_INFO       $fastcgi_path_info;
                fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
       }
   }
#安装redis
mkdir ~/src/redis
wget http://download.redis.io/releases/redis-3.0.2.tar.gz
tar xzf redis-3.0.2.tar.gz
cd redis-3.0.2
make
sudo make install

#将生成的程序文件放到~/src/redis/下

# 启动配置
 cd ~
 mkdir redis
 把redis.conf复制到~/redis/
 vi redis.conf 后台运行 redis
 修改 daemonize yes
 # 启动server
 redis-server redis.conf &
 # 启动client
 redis-cli -p 6379

cp ./src/redis_* ~/src/redis/

#ssdb安装
mkdir ~/src/redis
wget --no-check-certificate https://github.com/ideawu/ssdb/archive/master.zip
unzip master
cd ssdb-master
make clean
make
sudo make install  #ssdb 默认安装到 /usr/local/ssdb
# 配置环境变量
 vi ~/.bash_profile
 加入PATH环境变量: /usr/local/ssdb
 例如: export PATH=/usr/local/ssdb:$PATH
 source ~/.bash_profile

 # 启动配置
 cd ~
 mkdir ssdb
 把ssdb.conf复制到~/ssdb/
 mkdir var
 # 基本命令(以下命令要在ssdb.conf所在的目录下执行)
 # or start as daemon
 ssdb-server -d ssdb.conf
 # ssdb command line
 ssdb-cli -p 8888
 # stop ssdb-server
 ssdb-server ssdb.conf -s stop

#postgres安装
wget https://ftp.postgresql.org/pub/source/v9.3.5/postgresql-9.3.5.tar.gz
tar zxf postgresql-9.3.5.tar.gz
cd postgresql-9.3.5
./configure
make
sudo make install

配置环境变量
 vi ~/.bash_profile
 加入
 export PGDATA=/Users/apple/postgresql/data
 export PATH=/usr/local/pgsql/bin:$PATH
 生效
 source ~/.bash_profile
 初始化数据库
 initdb
 启动数据库
 pg_ctl start
 创建超级用户postgres
 createuser postgres -s (创建最高权限用户，相当于mysql里的root账户)

 进入到客户端
 psql -U postgres
 常用命令
 \l    		#显示所有数据
 \c dbname    	#连接到dbname的数据库
 \q 		#退出客户端
 \d 		#所有当前库所有的表
 \d tablename    #查看tablename的表字段

#php7安装
 tar -zxvf php-7.1.4.tar.gz
 cd php-7.1.4
 ./configure --with-pgsql --with-pdo-pgsql --with-openssl=/usr/local/opt/openssl/ --with-mcrypt --enable-zip --enable-mbstring --enable-fpm --enable-opcache  --with-curl --with-libedit=/usr/local/opt/libedit  --enable-pcntl   --enable-sysvmsg  --with-zlib-dir=/usr/local/opt/zlib   --with-gd --with-jpeg-dir=/usr/local/opt/jpeg/  --with-png-dir=/usr/local/opt/libpng/ --with-freetype-dir=/usr/local/opt/freetype --with-iconv=/usr/local/opt/libiconv/  --enable-bcmath

 make
 sudo make install

#编译安装完成后，在PHP源码目录执行下面命令
cp php.ini-production /usr/local/lib/php.ini

#编辑时区
vi /usr/local/lib/php.ini

# 查找timezone,修改
date.timezone = "Asia/Shanghai"
always_populate_raw_post_data = -1

#查找max_execution_time，修改执行时间
max_execution_time = 300

#在PHP安装源码目录，执行下面的命令，fpm 安装
sudo cp sapi/fpm/php-fpm.conf /usr/local/etc/

sudo cp sapi/fpm/php-fpm  /usr/local/bin/

# 修改fpm配置
vi /usr/local/etc/php-fpm.conf
# 查找clear_env
clear_env=no

# 最长执行时间
request_terminate_timeout = 300

# 打开PHP错误日志输出到php_error.log文件
catch_workers_output = yes

将以下内容拷贝到/usr/local/sbin/fpm中
vi /usr/local/sbin/fpm
#!/bin/bash
USER=`whoami`

PHP_CGI=/usr/local/sbin/php-fpm
PHP_CGI_NAME=`basename $PHP_CGI`
RETVAL=0

start() {
      echo -n "Starting PHP FPM: "
      $PHP_CGI
      RETVAL=$?
      echo "$PHP_CGI_NAME."
}
stop() {
      echo -n "Stopping PHP FPM: "
      killall -QUIT  -u $USER php-fpm
      RETVAL=$?
      echo "$PHP_CGI_NAME."
}

case "$1" in
    start)
      start
  ;;
    stop)
      stop
  ;;
    restart)
      stop
      start
  ;;
    *)
      echo "Usage: fpm {start|stop|restart}"
      exit 1
  ;;
esac
exit $RETVA

#将fpm文件改为可执行文件 确保fpm在环境变量PATH中
chmod 777 /usr/local/sbin/fpm
启动: fpm start
关闭: fpm stop
重启: fpm restart
# 注意，更改环境变量，必须要重启

7.phalcon安装
 wget https://github.com/phalcon/cphalcon/archive/v3.1.2.tar.gz -O cphalcon-3.1.2.tar.gz
 tar -zxvf cphalcon-3.1.2.tar.gz
 cd cphalcon-3.1.2/build
 sudo ./install

 #php添加phalcon扩展
 vi /usr/local/lib/php.ini
 添加
 extension=phalcon.so

 #php添加redis扩展
 git clone https://github.com/phpredis/phpredis.git
 phpize
 ./configure
 make
 sudo make install
 生成的phpredis.so要加载到php.ini
 vi /usr/local/lib/php.ini
 extension = redis.so

 #php添加ssdb扩展
git clone https://github.com/jonnywang/phpssdb.git
解压文件，进入目录，依次执行
git checkout php7
phpize
./configure
make
sudo make install
生成的ssdb.so要加载到php.ini
vi /usr/local/lib/php.ini
extension = ssdb.so
重启php-fpm