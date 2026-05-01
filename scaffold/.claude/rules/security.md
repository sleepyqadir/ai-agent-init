## Security

- No hardcoded secrets. Keys, tokens, passwords, and connection strings live in environment variables only.
- Validate all input at system boundaries: HTTP request bodies, query params, path params, webhook payloads.
- Parameterized queries for all database operations. String concatenation into SQL is never acceptable.
- Sanitize output. Never use `innerHTML`, `dangerouslySetInnerHTML`, or `document.write` without sanitization.
- Never use `eval()`, `new Function()`, or `exec()` with user-controlled input.
- Auth tokens: short expiry, httpOnly cookies or secure storage, never in localStorage for sensitive tokens.
- Set security headers: CORS policy, CSP, X-Content-Type-Options, X-Frame-Options, Referrer-Policy.
- Log security events (auth failures, permission denials, anomalies). Never log secrets or credentials.
- Run `npm audit` / `pip audit` on dependency changes. Pin versions in production manifests.
- Rate-limit all public endpoints. Authentication endpoints get stricter limits.
- OWASP Top 10 awareness: injection, broken auth, sensitive data exposure, broken access control, misconfiguration, XSS, insecure deserialization, vulnerable components, insufficient logging.
