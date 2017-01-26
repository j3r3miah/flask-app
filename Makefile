
all: build up


build: down _clean_up_after_uwsgi
	docker-compose build
_clean_up_after_uwsgi:
	rm -f app/uwsgi.sock


up:
	docker-compose up -d
down:
	docker-compose down
logs:
	docker-compose logs -f


psql: _db_start
	docker-compose run --rm -e PGPASSWORD=password base \
	    psql -h db -U postgres app_dev
_db_start:
	docker-compose up -d db && sleep 2


db_reset: _db_reset _db_first_start
	docker-compose run --rm -e PGPASSWORD=password base \
	    psql -h db -U postgres -c 'CREATE DATABASE app_dev;'
	docker-compose run --rm base python3 manage.py db init
	docker-compose run --rm base python3 manage.py db migrate
	docker-compose run --rm base python3 manage.py db upgrade
_db_reset:
	# delete persistent docker volume (postgres data files)
	docker-compose down -v
_db_first_start:
	docker-compose up -d db && sleep 20


db_migrate: _db_start
	docker-compose run --rm base python3 manage.py db migrate

db_upgrade: _db_start
	docker-compose run --rm base python3 manage.py db upgrade
