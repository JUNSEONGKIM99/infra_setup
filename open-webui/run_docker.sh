docker run -d \
  --name open-webui \
  --network data-network \
  -p 127.0.0.1:8094:8080 \
  -v open-webui-data:/app/backend/data \
  my-webui
