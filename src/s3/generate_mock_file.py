import os
from faker import Faker

fake = Faker()

N_ROWS = 1000
OUTPUT_NAME = "mock.csv"


if os.path.isfile(OUTPUT_NAME):
    os.remove(OUTPUT_NAME)

f = open(OUTPUT_NAME, "x")
header = "user_id, timestamp, currency_code\n"
f.write(header)

for _ in range(N_ROWS):
    user_id = fake.pyint()
    timestamp = fake.date_time()
    currency_code = fake.currency_code()
    line = "{}, {}, {}\n".format(user_id, timestamp, currency_code)
    f.write(line)

f.close()
