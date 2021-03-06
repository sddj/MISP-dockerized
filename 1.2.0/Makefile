.PHONY: help \
		start requirements build-config deploy delete change-ssl disable-maintenance enable-maintenance\
		security configure config-db config-server config-proxy \
		backup-all backup-server backup-redis backup-db backup-proxy backup-robot \
		build-server build-proxy build-robot build-all \

# Shows Help and all Commands
help:
	@scripts/help.sh
	
# Start
install: requirements build-config pull deploy
	@echo " ###########	Improve Environment	###########"
	@echo "To improve your performance please execute and add the following to /etc/rc.local:"
	@echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
	@echo "echo 1024 > /proc/sys/net/core/somaxconn"
	@echo "sysctl vm.overcommit_memory=1"
	@echo " ##################################################"
	@echo 
	@echo

####################	used as host	####################
# Check requirements
requirements:
	@echo " ###########	Checking Requirements	###########"
	@scripts/requirements.sh
	@sleep 2

# Create Support Package
support:
	make -C ../ support

# Show MISP Information
version:
	docker exec misp-server echo "$$VERSION"

# Build Configuration
build-config:
	@echo " ###########	Build Configuration	###########"
	@scripts/build_config.sh $(REPOURL)
	@sleep 2

# Start Docker environment
pull:
	@echo " ###########	Pull Environment	###########"
	@scripts/pull.sh

deploy: 
	@echo " ###########	Deploy Environment	###########"
	@scripts/deploy.sh
	@echo " ###########	MISP environment is ready	###########"
	@echo "Please go to: https://$(shell cat config/config.env|grep MISP_FQDN|cut -d = -f 2)"
	@echo "Login credentials:"
	@echo "      Username: admin@admin.test"
	@echo "      Password: admin"
	@echo
	@echo "Do not forget to add / change your SSL certificate with:    make change-ssl"
	@echo "Do not forget to add / change your S/MIME certificate with:    make change-smime"
	@echo "Do not forget to add / change your PGP certificate with:    make change-pgp'"
	@echo
	@echo "MISP now finishes some configuration tasks to ensure that everything works properly."
	@echo "It may take 5-10 minutes for MISP to become fully available."
	@echo "Please do not turn off or restart the server during this time."
	@echo
	@echo


# delete all misp container, volumes and images
delete: copy-ssl_without_restart
	@scripts/delete_misp_from_host.sh --container --network

delete-volumes: copy-ssl_without_restart
	@scripts/delete_misp_from_host.sh --volumes --container --network

delete-images: copy-ssl_without_restart
	@scripts/delete_misp_from_host.sh --images --container --network

delete-all: copy-ssl_without_restart
	@scripts/delete_misp_from_host.sh --images --container --network --volumes --prune



# stop all misp docker container
stop-all:
	docker stop misp-server
	docker stop misp-proxy
	docker stop misp-modules
	docker stop misp-robot

# start all misp docker container
start-all:
	docker start misp-server
	docker start misp-proxy
	docker start misp-modules
	docker start misp-robot

# restart all misp docker container
restart-all: stop-all start-all

# upgrade to a new version
upgrade:
	@echo " ###########	Upgrade MISP-dockerized to a new version	###########"
	@cd ../
	@UPGRADE.sh

# Update current MISP to all new functions in this Version without a new version
update: pull deploy


test:
	@make -C ../.ci test

# backup all services
backup-all:
	@scripts/backup_restore.sh backup all
backup-server:
	@scripts/backup_restore.sh backup server
backup-redis:
	@scripts/backup_restore.sh backup redis
backup-db:
	@scripts/backup_restore.sh backup mysql
backup-proxy:
	@scripts/backup_restore.sh backup proxy
backup-robot:
	@scripts/backup_restore.sh backup robot
backup-ssl: copy-ssl

# restore service
restore:
	@scripts/backup_restore.sh restore all

# restore-all:
# 	@scripts/backup_restore.sh restore all

# restore-server:
# 	@scripts/backup_restore.sh restore server

# restore-redis:
# 	@scripts/backup_restore.sh restore redis

# restore-db:
# 	@scripts/backup_restore.sh restore mysql

# restore-proxy:
# 	@scripts/backup_restore.sh restore proxy

# restore-robot:
# 	@scripts/backup_restore.sh restore robot

# restore-config:
# 	@scripts/backup_restore.sh restore config

####################	used in misp-robot	####################

# configure
configure:
	@echo " ###########	Configure Environment	###########	"
	make copy-smime
	make copy-pgp
	make config-ssl

# x509 SSL Certificate
change-ssl: config-ssl
	docker restart misp-server
	docker restart misp-proxy
config-ssl: copy-ssl_without_restart
copy-ssl_without_restart:
	-docker cp $(CURDIR)/config/ssl/cert.pem misp-proxy:/etc/nginx/ssl/
	-docker cp $(CURDIR)/config/ssl/key.pem misp-proxy:/etc/nginx/ssl/
	-docker cp $(CURDIR)/config/ssl/ssl.passphrase misp-proxy:/etc/nginx/ssl/
	-docker cp misp-proxy:/etc/nginx/ssl/cert.pem $(CURDIR)/config/ssl/
	-docker cp misp-proxy:/etc/nginx/ssl/key.pem $(CURDIR)/config/ssl/
	-docker cp misp-proxy:/etc/nginx/ssl/ssl.passphrase $(CURDIR)/config/ssl/

# x509 SSL Passphrase
change-ssl-passphrase: copy-ssl-passphrase
copy-ssl-passphrase:
	-docker cp $(CURDIR)/config/ssl/ssl.passphrase misp-proxy:/etc/nginx/ssl/

# S/MIME
change-smime: copy-smime
copy-smime:
	-docker cp $(CURDIR)/config/smime/cert.pem misp-server:/var/www/MISP/.smime/
	-docker cp $(CURDIR)/config/smime/key.pem misp-server:/var/www/MISP/.smime/

# GnuPGP
change-pgp: copy-pgp
copy-pgp:
	-docker cp $(CURDIR)/config/pgp/*.asc misp-server:/var/www/.gnupg/
	docker exec misp-server change-pgp

##############################
#	Performance Section
#
mysql-report:
	@docker exec -ti misp-db sh -c "mysqlreport --user $(shell cat $(CURDIR)/config/config.env|grep DB_USER|cut -d = -f 2) --password $(shell cat $(CURDIR)/config/config.env|grep DB_PASSWORD|cut -d = -f 2)"

mysql-performance-test:
	docker exec -ti misp-robot sh -c "/scripts/test_mysql_performance.sh"