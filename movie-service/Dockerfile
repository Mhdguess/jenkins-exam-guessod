FROM python:3.8-slim

WORKDIR /app

# Définir les variables d'environnement par défaut
ENV DATABASE_URI="sqlite:///:memory:"
ENV CAST_SERVICE_HOST_URL="http://localhost:8000/api/v1/casts/"

COPY ./requirements.txt /app/requirements.txt

RUN apt-get update \
    && apt-get install gcc -y \
    && apt-get clean

RUN pip install -r /app/requirements.txt \
    && rm -rf /root/.cache/pip

COPY . /app/

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--loop", "asyncio"]
