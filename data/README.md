# Data for the book's databases

CSV files that the SQL scripts and the Kotlin examples load into the book's own
small databases. They ship with the rendered book as downloads.

Only data created for the book belongs here. Public sample databases are not
redistributed; `../sql/public/` holds instructions or scripts that fetch them
from their sources. Data that informs a chapter but is not ours (client data,
licensed data, homework data sets) belongs in the private course archive, never
here.

| File | Holds | Used in |
|---|---|---|
| `new-customers.csv` | The 22 customers that stage G adds, clean | Loading data from files (`@sec-ddl-loading`) |
| `new-customers-raw.csv` | The same customers as a colleague exported them: one listed twice, one state typed `ok ` | `@sec-ddl-loading` |
| `april-orders-raw.csv` | Those customers' 40 orders of April 2026; the orders from April 13 on have month/day/year dates | `@sec-ddl-loading` exercises |

All three are written from the stage G database by
`scripts/build-load-data.py`; do not edit them by hand. The problems in the raw
files are planted on purpose, for the chapter to find with queries.

| File | Holds | Used in |
|---|---|---|
| `gauge-L7005-09.csv` | A gauge's readings for axle lot L7005-09, which stage Q has not recorded | Recording an inspection from a program (`@sec-prog-crud`) |
| `gauge-L7005-10.csv` | The next lot's readings, with one characteristic misspelled (`Lenght`) | The same section: a transaction that fails and records nothing |

These two files were written by hand for the book, as a gauge would export
them.

| File | Holds | Used in |
|---|---|---|
| `frame-line-replications.csv` | Three responses (`LotsCompleted`, `TimeInShop`, `WorkInProcess`) of every replication of the frame line's two scenarios, long | Querying files with DuckDB (`@sec-appembedded-duckdb`) |

It is written from stage K's `ksl_db.within_rep_view` by
`scripts/build-load-data.py`; do not edit it by hand.
