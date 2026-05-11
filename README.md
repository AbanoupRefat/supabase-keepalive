#  Supabase Keepalive Solution

A lightweight, zero-cost solution to prevent your free-tier Supabase projects from pausing due to inactivity.

---

##  The Problem

Supabase free tier projects are automatically **paused after 7 days of inactivity**. This is a major inconvenience for hobby projects, staging environments, or internal tools that aren't accessed daily, requiring manual restoration each time.

---

##  The Solution

Instead of paying for the Pro plan or manually clicking "Restore" every week, this solution uses a lightweight SQL setup and a free external cron job (like [cron-job.org](https://cron-job.org) or GitHub Actions) to perform a periodic "ping". This keeps the project active indefinitely without any cost.

---

##  How It Works

```
Every 5 Days:
  Cron Job (External)
      │
      │  POST /rest/v1/rpc/ping_keepalive
      ▼
  Supabase API (RPC)
      │
      │  Execute ping_keepalive()
      ▼
  Database (_keepalive table)
      │
      │  Update last_ping & ping_count
      ▼
  200 OK → Project stays active 
```

---

##  Setup Instructions

### 1. Database Setup

Run the following script in your **Supabase SQL Editor**. It creates a tracking table and a secure function to handle the pings automatically.

```sql
-- Create the tracking table
CREATE TABLE IF NOT EXISTS public._keepalive (
    id          serial PRIMARY KEY,
    project     text NOT NULL DEFAULT 'default',
    last_ping   timestamp with time zone DEFAULT now(),
    ping_count  bigint DEFAULT 0
);

-- Insert initial row (Replace 'your-project-name' with your identifier)
INSERT INTO public._keepalive (project) VALUES ('your-project-name')
ON CONFLICT DO NOTHING;

-- Create a function to automate the ping logic
CREATE OR REPLACE FUNCTION public.ping_keepalive(project_id text)
RETURNS void AS $$
BEGIN
    UPDATE public._keepalive
    SET last_ping = now(),
        ping_count = ping_count + 1
    WHERE project = project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant access to the anon role so the API can trigger it
GRANT EXECUTE ON FUNCTION public.ping_keepalive(text) TO anon;
```

---

### 2. Automation Options

#### Option A: Using Cron-job.org (Free & Simple)

1. Create a free account on [cron-job.org](https://cron-job.org).
2. Create a new Cronjob with these settings:

| Setting | Value |
|--------|-------|
| **URL** | `https://[YOUR_PROJECT_REF].supabase.co/rest/v1/rpc/ping_keepalive` |
| **Method** | `POST` |
| **Schedule** | Every 5 days |

3. Add the following **Headers**:

```
apikey: YOUR_ANON_KEY
Authorization: Bearer YOUR_ANON_KEY
Content-Type: application/json
```

4. Set the **Body (Raw JSON)**:

```json
{"project_id": "your-project-name"}
```

---

#### Option B: Using GitHub Actions

Create a file at `.github/workflows/keepalive.yml` in your repository:

```yaml
name: Supabase Keepalive

on:
  schedule:
    - cron: '0 8 */5 * *' # Runs at 08:00 every 5 days
  workflow_dispatch:       # Allows manual trigger for testing

jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Ping Supabase API
        run: |
          curl -X POST "${{ secrets.SUPABASE_URL }}/rest/v1/rpc/ping_keepalive" \
          -H "apikey: ${{ secrets.SUPABASE_ANON_KEY }}" \
          -H "Authorization: Bearer ${{ secrets.SUPABASE_ANON_KEY }}" \
          -H "Content-Type: application/json" \
          -d '{"project_id": "your-project-name"}'
```

> **Note:** Make sure to add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to your **GitHub Repository Secrets**.

---

## 🛠 Troubleshooting

| Symptom | Cause & Fix |
|---------|-------------|
| **Project still pausing** | Check your cron schedule — it must run at least every 7 days. 5 days is recommended. |
| **401 Unauthorized** | Double-check your `anon` key in the request headers. |
| **404 Not Found** | Verify your Project Reference ID in the URL and confirm the SQL function exists in the `public` schema. |

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
