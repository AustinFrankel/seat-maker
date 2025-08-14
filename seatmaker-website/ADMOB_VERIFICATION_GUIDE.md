# AdMob Verification Fix Guide

## ✅ Issues Fixed

### 1. **app-ads.txt Formatting Issues**
- **Problem**: File contained extra blank lines and hidden characters
- **Solution**: Created clean `app-ads.txt` with exact content:
  ```
  google.com, pub-9106410979255644, DIRECT, f08c47fec0942fa0
  ```
- **Location**: `/public/app-ads.txt`

### 2. **Domain Mismatch Issues**
- **Problem**: CNAME showed `app.seatmakerapp.com` but website used `seatmaker.app`
- **Solution**: Updated CNAME to `seatmaker.app` for consistency
- **Files Updated**: 
  - Root `/CNAME`
  - `/public/CNAME`

### 3. **Next.js Configuration**
- **Added**: Proper headers for `app-ads.txt` serving
- **Added**: Cache control to prevent stale content
- **Added**: Content-Type specification for text files

## 🌐 Domain Configuration

**Current Configuration:**
- **Primary Domain**: `seatmaker.app`
- **CNAME**: `seatmaker.app`
- **App Store Support URL**: Should be `https://seatmaker.app`

## 📋 Next Steps for AdMob Verification

### 1. **Update App Store Connect**
- Go to App Store Connect → Your App → App Information
- Update **Support URL** to: `https://seatmaker.app`
- Remove any `/path` or `www.` prefixes
- Ensure it's exactly `https://seatmaker.app`

### 2. **Verify File Accessibility**
- Test: `https://seatmaker.app/app-ads.txt`
- Should show exactly: `google.com, pub-9106410979255644, DIRECT, f08c47fec0942fa0`
- No extra spaces, quotes, or hidden characters

### 3. **DNS Configuration**
- Ensure both `www.seatmaker.app` and `seatmaker.app` point to the same hosting
- Both should serve the exact same `app-ads.txt` file
- No redirects between domains

### 4. **Wait for Propagation**
- DNS changes can take up to 24 hours
- AdMob crawler may take additional time to detect changes
- Use "Check for updates" in AdMob after making changes

## 🔍 Verification Checklist

- [ ] `app-ads.txt` accessible at `https://seatmaker.app/app-ads.txt`
- [ ] File contains exactly the required line (no extra characters)
- [ ] App Store Support URL matches exactly: `https://seatmaker.app`
- [ ] Both www and non-www versions serve the same file
- [ ] No redirects or SSL issues
- [ ] File served with `text/plain` content type

## 🚨 Common Issues to Avoid

1. **Extra Characters**: Don't copy-paste from Word/Google Docs
2. **Domain Mismatch**: Support URL must match hosting domain exactly
3. **Protocol Mismatch**: Use `https://` consistently
4. **Path Issues**: Don't include `/path` in Support URL
5. **Caching**: Clear any CDN or browser cache

## 📞 Support

If verification still fails after following these steps:
1. Wait 24-48 hours for propagation
2. Check AdMob error messages for specific issues
3. Verify file accessibility from different locations
4. Ensure no CDN or hosting platform interference
