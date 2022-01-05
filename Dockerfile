# Flask bir Python framework'ü olduğu için Python yüklü olmalıdır.
# Alpine küçük boyutlu bir image olduğu ve Python ile resmi image'ı olduğu işimizi görecektir. 
FROM python:alpine

# Uygulamamızı /app klasörüne kopyalıyoruz.
COPY . /app

# /app directory'sine geçiyoruz.
WORKDIR /app

# Flask yüklüyoruz
RUN pip install flask

# 5000 portundan yayın yapıyoruz.
EXPOSE 5000

# Uygulamamızı çalıştırıyoruz.
CMD ["python", "app.py"]