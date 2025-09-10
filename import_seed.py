import csv
from pathlib import Path

src = Path("/workspaces/dbt-case/data/currencies.csv")
dst = Path("/workspaces/dbt-case/transformation/seeds/currencies.csv")
dst.parent.mkdir(parents=True, exist_ok=True)

with src.open("r", encoding="utf-8", newline="") as inf, \
     dst.open("w", encoding="utf-8", newline="") as outf:
    reader = csv.reader(inf, delimiter=";")
    writer = csv.writer(outf, delimiter=",", quoting=csv.QUOTE_MINIMAL)
    for row in reader:
        writer.writerow(row) 

print(f"Add table as seed: {dst}")