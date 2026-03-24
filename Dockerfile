FROM nginx:1.27-alpine

COPY nginx/tenants-api/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
