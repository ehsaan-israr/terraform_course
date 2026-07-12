FROM nginx:1.27-alpine

# Install curl for optional debugging; add custom health page
RUN apk add --no-cache curl \
    && mkdir -p /usr/share/nginx/html/health

COPY html/index.html /usr/share/nginx/html/index.html
COPY html/health/index.json /usr/share/nginx/html/health/index.json
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Non-root-friendly: nginx alpine runs as root by default; document for production hardening in later modules
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1
