# Use the official OpenResty base image
FROM openresty/openresty:alpine

# Set the working directory
WORKDIR /app/data

# Install required packages and Lua modules
RUN apk add --no-cache \
    lua5.1 lua5.1-cjson luarocks lua5.1-dev build-base ca-certificates && \
    /usr/bin/luarocks-5.1 install lua-resty-http && \
    /usr/bin/luarocks-5.1 install luafilesystem

# Update CA certificates
RUN update-ca-certificates

# Create directory for fetched files
RUN mkdir -p /usr/local/openresty/nginx/fetched

# Copy server files to the container
COPY server /usr/local/openresty/nginx/lua

# Set up Nginx configuration
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Expose port 8080
EXPOSE 8080

# Start OpenResty
CMD ["openresty", "-g", "daemon off;"]

