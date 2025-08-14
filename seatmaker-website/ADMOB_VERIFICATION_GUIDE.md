# AdMob Verification Guide for Seat Maker

## Current Status: ❌ NOT VERIFIED
**Error**: "We couldn't verify Seat Maker (iOS)"

## Required app-ads.txt Content
Your app-ads.txt file should contain exactly:
```
google.com, pub-9106410979255644, DIRECT, f08c47fec0942fa0
```

## File Location
The app-ads.txt file is located at:
- **Local Development**: `public/app-ads.txt`
- **Production**: `https://www.seatmakerapp.com/app-ads.txt`

## Verification Steps

### 1. Verify File Content
✅ **Content is correct** - The file contains the exact required text

### 2. Verify File Accessibility
The file should be accessible at: `https://www.seatmakerapp.com/app-ads.txt`

### 3. Check Domain Configuration
- **CNAME**: `seatmaker.app` ✅
- **App Store Domain**: Must match exactly

### 4. Common Issues & Solutions

#### Issue: File not found at root domain
**Solution**: Ensure the file is in the `public/` directory and deployed to production

#### Issue: Domain mismatch
**Solution**: Verify that `seatmaker.app` is exactly what's listed in your App Store listing

#### Issue: Caching issues
**Solution**: Clear CDN cache and wait for propagation

### 5. Testing Steps

1. **Local Test**: Visit `http://localhost:3000/app-ads.txt`
2. **Production Test**: Visit `https://www.seatmakerapp.com/app-ads.txt`
3. **Content Verification**: Ensure the file shows exactly:
   ```
   google.com, pub-9106410979255644, DIRECT, f08c47fec0942fa0
   ```

### 6. Next Steps

1. **Deploy to Production**: Ensure the updated app-ads.txt is live
2. **Wait for Propagation**: DNS changes can take up to 48 hours
3. **Re-run Verification**: In AdMob console after deployment
4. **Contact Support**: If issues persist after 48 hours

## Technical Details

- **Publisher ID**: `pub-9106410979255644`
- **Account Type**: `DIRECT`
- **Certification Authority ID**: `f08c47fec0942fa0`
- **File Format**: Plain text, no BOM, UTF-8 encoding
- **Line Endings**: Unix (LF) or Windows (CRLF) - both acceptable

## Troubleshooting Commands

```bash
# Check if file is accessible locally
curl http://localhost:3000/app-ads.txt

# Check if file is accessible in production
curl https://www.seatmakerapp.com/app-ads.txt

# Verify file content
cat public/app-ads.txt
```

## Support Resources

- [AdMob Help Center](https://support.google.com/admob/)
- [IAB Tech Lab app-ads.txt Specification](https://iabtechlab.com/app-ads-txt/)
- [Google AdMob Community](https://support.google.com/admob/community)
