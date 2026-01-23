import os

from sqlalchemy import (Column, DateTime, Integer, MetaData, String, Table,
                        create_engine)
from sqlalchemy import JSON

from databases import Database

# Utiliser une valeur par défaut si DATABASE_URI n'est pas définie
DATABASE_URI = os.getenv('DATABASE_URI', 'sqlite:///:memory:')

engine = create_engine(DATABASE_URI)
metadata = MetaData()

movies = Table(
    'movies',
    metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String(50)),
    Column('plot', String(250)),
    Column('genres', JSON),
    Column('casts_id', JSON)
)

database = Database(DATABASE_URI)
