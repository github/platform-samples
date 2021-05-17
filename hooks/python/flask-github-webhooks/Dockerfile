FROM python:2.7
LABEL version="1.0"
LABEL description="Flask-based webhook receiver"

WORKDIR /app

COPY webhooks.py /app/webhooks.py
COPY config.json.sample /app/config.json
COPY requirements.txt /app/requirements.txt
COPY hooks /app/hooks
RUN pip install -r requirements.txt

EXPOSE 5000
CMD ["python", "webhooks.py"]
