# Caddy + Cloudflare DNS Plugin Docker Build Fix Guide

## Problem Summary

Your Docker build for Caddy with the Cloudflare DNS plugin is failing with this error:

```
go: github.com/caddy-dns/cloudflare@v0.2.1 requires go >= 1.23.0 (running go 1.22.12; GOTOOLCHAIN=local)
```

**Root Cause**: The latest version of the `caddy-dns/cloudflare` plugin (v0.2.1) requires Go 1.23.0 or higher, but your Dockerfile uses `golang:1.22-alpine`.

## 🎯 **RECOMMENDED SOLUTION: Update Go Version**

### Updated Dockerfile

Replace your current `Caddy.dockerfile` with this fixed version:

```dockerfile
# Multi-stage build for Caddy with Cloudflare DNS plugin
# Stage 1: Build Caddy with plugins
FROM golang:1.23-alpine AS builder

# Install git (required for xcaddy to fetch dependencies)
RUN apk add --no-cache git

# Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Build Caddy v2.7.6 with the Cloudflare DNS plugin
RUN /go/bin/xcaddy build v2.7.6 --with github.com/caddy-dns/cloudflare

# Stage 2: Final image based on official Caddy image
FROM caddy:2.7.6

# Copy the custom-built Caddy binary from the builder stage
COPY --from=builder /go/caddy /usr/bin/caddy

# Expose standard HTTP and HTTPS ports
EXPOSE 80 443

# Use the default Caddy entrypoint
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
```

### What Changed and Why

| **Component** | **Before** | **After** | **Reason** |
|---------------|------------|-----------|------------|
| **Base Image** | `golang:1.22-alpine` | `golang:1.23-alpine` | Plugin requires Go 1.23.0+ |
| **Build Process** | ❌ Failed at plugin build | ✅ Successfully builds | Version compatibility resolved |
| **Plugin Support** | ❌ Not supported | ✅ Full Cloudflare DNS support | Latest plugin features available |

## 🚀 **Quick Fix Instructions**

1. **Replace your Dockerfile**:
   ```bash
   # Navigate to your homelab directory
   cd ~/w/homelab
   
   # Backup your current Dockerfile (optional)
   cp Caddy.dockerfile Caddy.dockerfile.backup
   
   # Copy the fixed Dockerfile
   cp /home/ubuntu/Caddy.dockerfile ./Caddy.dockerfile
   ```

2. **Build and deploy**:
   ```bash
   # Build and start Caddy with the fix
   docker compose up -d --build caddy
   ```

3. **Verify the build**:
   ```bash
   # Check if Caddy is running with Cloudflare support
   docker logs caddy
   
   # Test Cloudflare DNS functionality
   docker exec caddy caddy version
   ```

## 🔄 **Alternative Solutions**

### Option 1: Try Older Plugin Version (If Main Solution Fails)

If for some reason you need to stick with Go 1.22, you can try an older version of the plugin:

```dockerfile
# Use this line instead in your Dockerfile builder stage:
RUN /go/bin/xcaddy build v2.7.6 --with github.com/caddy-dns/cloudflare@v0.1.0
```

**Note**: Older versions may lack recent features or security updates.

### Option 2: Use Latest Go Version (Future-Proofing)

For maximum compatibility and future-proofing, use the latest Go version:

```dockerfile
# Change the first line to:
FROM golang:1.25-alpine AS builder
```

### Option 3: Pre-built Image (If Build Still Fails)

As a last resort, you can use a community-built image:

```yaml
# In your docker-compose.yaml, replace the build section with:
caddy:
  image: caddy:2.7-builder  # Note: Find a suitable pre-built image
  # Remove the build section
```

## ✅ **Verification Steps**

After applying the fix, verify everything works:

### 1. Container Health Check
```bash
# Check if Caddy container is running
docker ps | grep caddy

# View Caddy logs for any errors
docker logs caddy --tail 50
```

### 2. Cloudflare Plugin Functionality
```bash
# Test if Cloudflare DNS challenges work
# This will be verified when Caddy tries to get certificates

# Check if your domains are accessible
curl -I https://movies.streetgeek.media
curl -I https://vault.carlparrish.com
```

### 3. SSL Certificate Validation
Your domains should automatically get SSL certificates via Cloudflare DNS validation. Monitor the logs:

```bash
# Watch for certificate acquisition
docker logs caddy -f | grep -i "certificate\|cloudflare\|dns"
```

## 🛠 **Your Docker Compose Configuration**

Your existing `docker-compose.yaml` is already correctly configured:

```yaml
caddy:
  build:
    context: .
    dockerfile: Caddy.dockerfile  # ✅ Correct
  environment:
    - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}  # ✅ Required
  # ... rest of config is good
```

**No changes needed** to your compose file - only the Dockerfile needed updating.

## 🔧 **Troubleshooting**

### Build Still Fails?

1. **Clear Docker build cache**:
   ```bash
   docker builder prune -a
   docker compose build --no-cache caddy
   ```

2. **Check Go version availability**:
   ```bash
   docker run --rm golang:1.23-alpine go version
   ```

3. **Verify Cloudflare API Token**:
   ```bash
   # Make sure your .env file has the token
   echo $CLOUDFLARE_API_TOKEN
   ```

### Runtime Issues?

1. **Check Cloudflare API permissions**:
   - Your token needs `Zone:Zone:Read` and `Zone:DNS:Edit` permissions
   - Token must have access to all domains in your Caddyfile

2. **DNS propagation delays**:
   - Wait 2-5 minutes for DNS changes to propagate
   - Check DNS with: `dig TXT _acme-challenge.yourdomain.com`

### Plugin Not Working?

1. **Verify plugin inclusion**:
   ```bash
   docker exec caddy caddy list-modules | grep cloudflare
   ```

2. **Check Caddyfile syntax**:
   Your current Caddyfile looks correct with:
   ```caddyfile
   {
       tls {
           dns cloudflare {env.CLOUDFLARE_API_TOKEN}
       }
   }
   ```

## 📋 **Summary**

| **Issue** | **Solution** | **Status** |
|-----------|--------------|------------|
| Go version too old | Updated to `golang:1.23-alpine` | ✅ Fixed |
| Plugin incompatible | Now uses compatible versions | ✅ Fixed |
| Build process failing | Multi-stage build optimized | ✅ Fixed |
| Docker compose config | No changes needed | ✅ Ready |

## 🎉 **Final Steps**

1. **Deploy the fix**:
   ```bash
   cd ~/w/homelab
   docker compose up -d --build caddy
   ```

2. **Monitor the deployment**:
   ```bash
   docker logs caddy -f
   ```

3. **Test your services**:
   - Visit your domains to verify SSL certificates
   - Check that all reverse proxy routes work correctly

Your Caddy server should now successfully build with Cloudflare DNS support and automatically manage SSL certificates for all your homelab services! 🚀

---

**Need help?** If you encounter any issues with this fix, check the troubleshooting section above or examine the Docker logs for specific error messages.
