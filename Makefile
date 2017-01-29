
DatabaseName = flaskapp

all: build up dns


build:
	docker-compose build

clean:
	# NOTE: deletes persistent docker volume (postgres data files!)
	docker-compose down -v
	docker-compose rm -f


up: dns
	docker-compose up -d base
down:
	docker-compose down

dns:
	docker-compose up -d dnsmasq
killdns:
	docker-compose stop dnsmasq nginx-proxy

logs:
	docker-compose logs -f base postgres

bounce:
	docker-compose stop base
	docker-compose up -d base


psql: _db_start
	docker-compose run --rm --no-deps -e PGPASSWORD=password postgres \
	    psql -h postgres -U postgres $(DatabaseName)


db_init: _db_first_start
	# NOTE: recreates a local database, deleting all data!
	docker-compose run --rm --no-deps base python3 manage.py recreate_db
	docker-compose run --rm --no-deps base python3 manage.py db init
	docker-compose run --rm --no-deps base python3 manage.py db migrate
	docker-compose run --rm --no-deps base python3 manage.py db upgrade

_db_start:
	docker-compose up -d postgres && sleep 2

_db_first_start:
	docker-compose up -d postgres && sleep 10
