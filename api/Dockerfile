# Canlifal API — Node 20 + yt-dlp (sesli oda müzik akış çözümleme için).
#
# yt-dlp, mobil oynatıcının (just_audio) ihtiyaç duyduğu googlevideo ses
# akış URL'sini üretir. Web iframe kullandığı için bundan etkilenmez; mobil
# uygulamada müziğin çalması yt-dlp'nin sunucuda kurulu olmasına bağlıdır.
FROM node:20-bookworm-slim

# yt-dlp + python3 (ffmpeg opsiyonel ama bazı formatlar için faydalı)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        ffmpeg \
        ca-certificates \
    && pip3 install --no-cache-dir --break-system-packages yt-dlp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Bağımlılıklar (cache katmanı)
COPY package.json package-lock.json ./
RUN npm ci

# Kaynak + build
COPY . .
RUN npm run build

ENV NODE_ENV=production
EXPOSE 4000

CMD ["node", "dist/index.js"]
