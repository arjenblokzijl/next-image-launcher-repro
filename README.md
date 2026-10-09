# Image optimizer crashes the function launcher when a local source answers 5xx

## Link to the code that reproduces this issue

This repository. Live deployment: https://next-image-launcher-repro.vercel.app

The whole reproduction is one route handler, `app/api/image/route.ts`:

```ts
export function GET() {
  return new Response(null, { status: 500 });
}
```

## To reproduce

1. Deploy this app to Vercel (no env vars, no config).
2. Request `/_next/image?url=%2Fapi%2Fimage&w=64&q=75` (or run `./repro.sh https://<deployment>.vercel.app`).
3. Open the deployment's runtime logs.

## Current vs. expected behavior

Current: the visitor gets `400 INVALID_IMAGE_OPTIMIZE_REQUEST`, and the logs show the source request (`/api/image`, 500) followed within 200 ms by a second invocation, logged against `/_next/image`, that crashes the launcher:

```
Failed to handle /_next/image?url=%2Fapi%2Fimage&w=64&q=75
Error: Cannot find module './.next/server/pages/_next/image.js'
Require stack:
- /var/task/___next_launcher.cjs
- /opt/rust/nodejs.js
```

It happens on every request; the failed source is not cached.

Expected: the optimizer answers the image request with an error status and does not call a function for `/_next/image`.

## Provide environment information

```
Next.js: 16.5.0-canary.3 (also 16.4.0 in our production app)
Node: 24 (nodejs24.x)
Deployment: Vercel, Node.js runtime
```

## Which area(s) are affected?

Image (next/image), Runtime

## Which stage(s) are affected?

Vercel (Deployed)

## Additional context

- `next start` answers the same request without errors; this only happens when deployed.
- The trigger is a 5xx or a timeout from the local source. With a source that answers 403 or 404, there is no crash.
- With a dynamic source route the crash carries the source's route params on the image path, for example `Failed to handle /_next/image?nxtPname=x.png` for `app/api/image/[name]/route.ts`. So the function is chosen from the source request, but it receives the outer `/_next/image` URL.
- `./.next/server/pages/_next/image.js` is a relative path required by `___next_launcher.cjs`. An App Router build has no such module.
- In our production app (Next 16.4.0, `trailingSlash: true`, a proxy that rewrites to a `[locale]` segment) this happened 35 times since 2026-07-26, always while the upstream behind the route handler was failing.
