FROM postgres:16
RUN apt update && apt install -y postgresql-16-postgis-3 postgresql-16-postgis-3-scripts ca-certificates && rm -rf /var/lib/apt/lists/*
USER postgres
