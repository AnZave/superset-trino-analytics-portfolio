FROM apache/superset:4.1.2

USER root
RUN pip install --no-cache-dir psycopg2-binary==2.9.10 sqlalchemy-trino==0.5.0
COPY superset_config.py /app/pythonpath/superset_config.py
COPY docker-init.sh /app/docker-init.sh
RUN chmod +x /app/docker-init.sh
USER superset

