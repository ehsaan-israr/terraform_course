FROM nginx:1.25-alpine

LABEL org.opencontainers.image.source="https://github.com/your-org/github-actions-terraform-eks-course"
LABEL environment="training"

COPY index.html /usr/share/nginx/html/index.html

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost/ || exit 1

EXPOSE 80
