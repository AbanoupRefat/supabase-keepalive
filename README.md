#  Supabase Keepalive Solution

A lightweight, zero-cost solution to prevent your free-tier Supabase projects from pausing due to inactivity.

##  The Problem
Supabase free tier projects are automatically paused after a week of inactivity. This is annoying for hobby projects, staging environments, or internal tools that aren't used daily.

##  The Solution
Instead of paying for the Pro plan or manually clicking "Restore" every week, this solution uses a lightweight SQL table in your project and a free external cron job (like `cron-job.org` or GitHub Actions) to perform a simple read operation every 5 days. This keeps the project active indefinitely.

##  How It Works (Visualization)

```mermaid
sequenceDiagram
    participant C as Cron Job (cron-job.org)
    participant S as Supabase API
    participant D as Database (_keepalive table)
    
    loop Every 5 Days
        C->>S: Send GET Request with Anon Key
        S->>D: Query _keepalive table
        D-->>S: Return last_ping timestamp
        S-->>C: 200 OK (Project stays active)
    end
