# Civicly

A civic grievance reporting and tracking app based on `spec.md`. Citizens can submit infrastructure issues, attach evidence, receive a rule-based severity estimate, and follow status updates. The public dashboard shows aggregate and recent report information without exposing citizen contact details. Admin accounts can manage report assignments and statuses.

## Run the demo

Serve this folder with any local static web server (ES modules require HTTP). For example, with Python installed:

```sh
python -m http.server 8000
```

Then open `http://localhost:8000`. With no Supabase configuration, Civicly uses browser local storage and a handful of clearly illustrative sample reports. Demo accounts and data remain on that browser only; this mode is for trying the interface, not production use. Create an account through **Sign in → Create account**. Local demo mode does not grant admin roles.

## Connect Supabase

1. Create a Supabase project.
2. Copy `config.example.js` to `config.js` and set `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the project API settings. Never put a service role key in browser code.
3. Run `supabase.sql` in the project SQL editor.
4. Register a trusted account, then promote it to admin in the SQL editor using the commented statement at the end of `supabase.sql`.
5. Set the Supabase Auth site URL and redirect URLs to your local or deployed app URL.

The SQL configures row-level security, a safe public complaint view, and a private evidence bucket. Citizens cannot change report status or assignment; only an admin profile can. Review the SQL policies and storage limits for your deployment needs before launch.

## Severity rules

`scoreIssue()` in `app.js` is isolated from submission and persistence. It adds a category baseline to weighted user inputs for urgency, people affected, and duration, clamps the result to 0–100, and maps it to Low (0–39), Medium (40–69), or High (70–100). Adjust these weights with your local authority before using for operational triage.
