FROM python:3.12-slim
WORKDIR /app
RUN pip install flask prometheus-client
COPY app.py .
ENV UPLOAD_DIR=/data
VOLUME ["/data"]
EXPOSE 80
CMD ["python","-m","flask","--app","app","run","--host","0.0.0.0","--port","80"]
