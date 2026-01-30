# Cloudflare Pages Redirects Proof

Generated: 2026-01-04

## _redirects Content

```bash
$ cat dist/public/_redirects
/api/* https://api.koomy.app/api/:splat 200
/objects/* https://api.koomy.app/objects/:splat 200
/wl.json /wl.json 200
/* /index.html 200
```

## API Base URL Resolution

The frontend now resolves the API base URL with the following priority:

1. `VITE_API_URL` environment variable
2. `VITE_API_BASE_URL` environment variable
3. Cached value from `wl.json`
4. Native platform default (`https://api.koomy.app`)
5. Domain detection: `*.koomy.app` or `koomy.app` -> `https://api.koomy.app`
6. Final fallback: `https://api.koomy.app`

Console log at boot: `[API] baseUrl resolved = https://api.koomy.app (source: ...)`

## Notes

- `/api/*` proxied to `https://api.koomy.app/api/:splat` - enables API calls from Pages domains
- `/objects/*` proxied to `https://api.koomy.app/objects/:splat` - enables object storage access
- `/wl.json` served directly (white-label config, before SPA catch-all)
- `/* /index.html 200` - SPA fallback (must be LAST)

## Build Scripts

| Script | File | Description |
|--------|------|-------------|
| `npm run build:pages` | `scripts/pages-redirects.mjs` | Generic Pages build (backoffice, saas, app-pro) |
| `npm run build:pages:unsalidl` | `scripts/build-pages-unsalidl.mjs` | White-label tenant build (includes wl.json) |

## Post-Build Verification

Both build scripts now include automatic verification that:
- `_redirects` file exists
- Contains `/api/*` proxy rule to `api.koomy.app`
- Contains `/objects/*` proxy rule

Build will FAIL if verification fails.

## Verification Commands

```bash
# Build and verify
npm run build:pages:unsalidl

# Manual check
cat dist/public/_redirects
```

## Test (after deployment)

```bash
curl -sSI https://backoffice.koomy.app/api/health | head -5
```

Expected: HTTP response from api.koomy.app (proxied).
