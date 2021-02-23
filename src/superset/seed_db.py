import psycopg2
from faker import Faker
from decouple import config
from datetime import datetime

import time

DB_PASSWORD = config('DB_PASSWORD')
DB_USER = config('DB_USER')
DEFAULT_DB = config('DEFAULT_DB')
DB_HOST = config('DB_HOST')
DB_PORT = config('DB_PORT')


con = psycopg2.connect(database=DEFAULT_DB, user=DB_USER,
                       password=DB_PASSWORD, host=DB_HOST, port=DB_PORT)

cur = con.cursor()


cur.execute("""
CREATE TABLE IF NOT EXISTS profiles(job TEXT,
  company TEXT, ssn TEXT,
  blood_group TEXT,
  name TEXT, sex TEXT, address TEXT,
  mail TEXT, birthdate TIMESTAMP)
""")

print("Generating data...")


insert_comand = ""
fake = Faker()
for _ in range(2000):
    profile = fake.profile()

    d = profile['birthdate']
    birthdate = datetime(
        year=d.year,
        month=d.month,
        day=d.day)

    command = "insert into profiles(job, company, ssn, blood_group, name, sex, address, mail, birthdate) values ('{}', '{}', '{}', '{}', '{}', '{}', '{}', '{}', '{}');".format(
        profile['job'].replace("'", ""), profile['company'], profile['ssn'], profile['blood_group'], profile['name'], profile['sex'], profile['address'], profile['mail'], birthdate)
    insert_comand += command

print("Data generated")

print("Inserting data...")
cur.execute(insert_comand)
con.commit()
print("Data inserted")


cur.execute("SELECT count(*) FROM profiles;")
rows = cur.fetchall()
print("Rows count:", rows)

con.commit()

con.close()
