# Multi-stage build for Romanian Septica PWA Frontend
# Stage 1: Build environment (if we had build tools, but this is a static PWA)
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files (if they exist, otherwise skip this step)
# Since this is a static PWA, we'll prepare the files
COPY . .

# Install any dependencies if package.json exists
RUN if [ -f "package.json" ]; then npm ci --only=production; fi

# Stage 2: Production nginx server
FROM nginx:1.25-alpine

# Install additional tools for production
RUN apk add --no-cache curl

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy static files from builder stage
COPY --from=builder /app /usr/share/nginx/html

# Copy custom nginx configuration optimized for PWA and WebSocket proxying
COPY <<EOF /etc/nginx/conf.d/default.conf
# Romanian Septica PWA Server Configuration
server {
    listen 80;
    server_name localhost;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy strict-origin-when-cross-origin;
    
    # Enable gzip compression for better performance
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json
        image/svg+xml;

    # Root directory for static files
    root /usr/share/nginx/html;
    index index.html;

    # Main location block for PWA
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Don't cache HTML and manifest files
        location ~* \.(html|json|webmanifest)$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
        
        # Service worker should never be cached
        location = /sw.js {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }

    # Proxy WebSocket connections to backend
    location /ws/ {
        proxy_pass http://septica-backend:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Proxy API calls to backend
    location /api/ {
        proxy_pass http://septica-backend:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 30s;
        proxy_connect_timeout 10s;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Security: Deny access to sensitive files
    location ~ /\. {
        deny all;
    }
    
    location ~ \.(md|txt|log|env)$ {
        deny all;
    }
}
EOF

# Health check configuration
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Expose HTTP port
EXPOSE 80

# Start nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]