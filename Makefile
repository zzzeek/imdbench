# Autogenerated by dataset/generate_data.py
.PHONY: new-dataset load-mongodb load-edgedb load-django load-sqlalchemy

CURRENT_DIR = $(shell pwd)

PSQL ?= psql
PYTHON ?= python
PP = PYTHONPATH=$(CURRENT_DIR) $(PYTHON)

# Autogenerated parameters
BUILD=$(abspath dataset/build/)

# Parameters that can be passed to 'dataset'
people?=100000
users?=100000
reviews?=500000


all:
	@echo "pick a target"

$(BUILD)/dataset.json: $(BUILD)/dataset.pickle.gz
	$(PP) -m dataset.jsonser

new-dataset:
	$(PP) -m dataset $(people) $(users) $(reviews)

load-mongodb:
	$(PP) -m _mongodb.loaddata

load-edgedb:
	$(PP) -m _edgedb.initdb
	$(PP) -m _edgedb.loaddata

load-django: $(BUILD)/dataset.json
	$(PSQL) -U postgres -tc \
		"DROP DATABASE IF EXISTS django_bench;" &> /dev/null
	$(PSQL) -U postgres -tc \
		"DROP ROLE IF EXISTS django_bench;" &> /dev/null
	$(PSQL) -U postgres -tc \
		"CREATE ROLE django_bench WITH \
			LOGIN ENCRYPTED PASSWORD 'edgedbbenchmark';" &> /dev/null
	$(PSQL) -U postgres -tc \
		"CREATE DATABASE django_bench WITH OWNER = django_bench;" \
		&> /dev/null

	$(PP) _django/manage.py flush --noinput
	$(PP) _django/manage.py migrate
	$(PP) -m _django.loaddata $(BUILD)/dataset.json

load-sqlalchemy: $(BUILD)/dataset.json
	$(PSQL) -U postgres -tc \
		"DROP DATABASE IF EXISTS sqlalch_bench;" &> /dev/null
	$(PSQL) -U postgres -tc \
		"DROP ROLE IF EXISTS sqlalch_bench;" &> /dev/null
	$(PSQL) -U postgres -tc \
		"CREATE ROLE sqlalch_bench WITH \
			LOGIN ENCRYPTED PASSWORD 'edgedbbenchmark';" &> /dev/null
	$(PSQL) -U postgres -tc \
		"CREATE DATABASE sqlalch_bench WITH OWNER = sqlalch_bench;" \
		&> /dev/null

	cd _sqlalchemy/migrations && $(PP) -m alembic.config upgrade head
	$(PP) _sqlalchemy/loaddata.py $(BUILD)/dataset.json