# Tasty AI service

This service keeps `OPENAI_API_KEY` on the server and exposes two routes:

- `GET /health`
- `POST /chat`

## Run locally

```bash
export OPENAI_API_KEY="your_key"
npm start
```

Deploy this directory to a Node.js 18+ host that provides HTTPS. Add `OPENAI_API_KEY` in the host's secret settings. Optionally set `OPENAI_MODEL`; the default is `gpt-5-mini`.

Then set the Tasty target's `AI_SERVICE_URL` build setting in Xcode to the deployed endpoint, for example `https://api.example.com/chat`.

Do not put your OpenAI API key in the iOS app. Before public release, protect this endpoint with app-user authentication and server-side subscription validation in addition to its included basic per-IP rate limit.
