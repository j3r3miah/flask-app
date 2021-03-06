import os
import yaml

from flask_script import Manager
from flask_migrate import Migrate, MigrateCommand, upgrade
from sqlalchemy_utils import database_exists, create_database, drop_database

from app import app, db

# models must be imported for migrations to work properly.
# load_fixtures needs them as well.
import app.models as app_models


manager = Manager(app)

migrate = Migrate(app, db)
manager.add_command('db', MigrateCommand)


@manager.command
def recreate_db():
    """ Recreates a local database. Do not use this on production. """
    db_uri = app.config['SQLALCHEMY_DATABASE_URI']

    if database_exists(db_uri):
        drop_database(db_uri)
    create_database(db_uri)


@manager.command
def load_fixtures(directory):
    """ Load database fixtures from `directory/*.yaml`. """
    recreate_db()
    upgrade()

    files = os.listdir(directory)
    files = [
        os.path.join(directory, f) for f in files if f.endswith('.yaml')
    ]

    for file in files:
        print("Loading fixtures: {}".format(file))

        with open(file, 'rb') as fixture:
            to_load = yaml.load(fixture.read())

        model = getattr(app_models, to_load['model'])
        objects = to_load['objects']

        for ob in objects:
            db.session.add(model(**ob))

    db.session.commit()


if __name__ == '__main__':
    manager.run()
