FROM alpine:3.10

RUN apk add --no-cache --update nodejs npm \
    git mysql mysql-client

RUN chown mysql:root -R /var/lib/mysql
RUN chgrp mysql -R /var/lib/mysql
RUN mkdir -p /run/mysqld 
RUN chown mysql:root /run/mysqld
RUN /usr/bin/mysql_install_db --user=mysql --ldata=/var/lib/mysql

# RUN sed -i 's/#bind-address/bind-address/g' /etc/my.cnf.d/mariadb-server.cnf
RUN sed -i 's/skip-networking/#skip-networking/g' /etc/my.cnf.d/mariadb-server.cnf


RUN mkdir /code
WORKDIR /code
COPY set_privileges.sql /code/set_privileges.sql

# Copy the starting app
COPY runapp.sh /code
RUN chmod +x /code/runapp.sh

# Start the application
ENTRYPOINT [ "/code/runapp.sh"]
EXPOSE 3001 3000