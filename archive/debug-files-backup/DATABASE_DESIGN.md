# Enhanced Cat vs Dog Voting App with PostgreSQL Backend
# Database Schema and Implementation Plan

## Database Design

### 1. Votes Table Schema
```sql
CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    vote_choice VARCHAR(10) NOT NULL CHECK (vote_choice IN ('cat', 'dog')),
    vote_source VARCHAR(20) NOT NULL CHECK (vote_source IN ('azure', 'onprem')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255)
);

-- Indexes for performance
CREATE INDEX idx_votes_choice ON votes(vote_choice);
CREATE INDEX idx_votes_source ON votes(vote_source);
CREATE INDEX idx_votes_timestamp ON votes(timestamp);
CREATE INDEX idx_votes_choice_source ON votes(vote_choice, vote_source);
```

### 2. Database Views for Analytics
```sql
-- Real-time vote counts by source
CREATE VIEW vote_counts_by_source AS
SELECT 
    vote_choice,
    vote_source,
    COUNT(*) as vote_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM votes 
GROUP BY vote_choice, vote_source
ORDER BY vote_choice, vote_source;

-- Overall vote summary
CREATE VIEW vote_summary AS
SELECT 
    vote_choice,
    COUNT(*) as total_votes,
    COUNT(CASE WHEN vote_source = 'azure' THEN 1 END) as azure_votes,
    COUNT(CASE WHEN vote_source = 'onprem' THEN 1 END) as onprem_votes
FROM votes 
GROUP BY vote_choice;

-- Hourly voting trends
CREATE VIEW hourly_voting_trends AS
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    vote_choice,
    vote_source,
    COUNT(*) as votes_per_hour
FROM votes 
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp), vote_choice, vote_source
ORDER BY hour DESC;
```

## Implementation Options

### Option 1: Azure Database for PostgreSQL (Recommended)
- **Shared Database**: Both Azure and on-premises apps connect to Azure Database for PostgreSQL
- **High Availability**: Built-in failover and backup
- **Global Access**: Accessible from both environments
- **Managed Service**: No maintenance overhead

### Option 2: On-Premises PostgreSQL with Replication
- **Primary**: PostgreSQL on your on-premises server
- **Replica**: Read replica in Azure
- **Cost Effective**: Lower cost but more maintenance

### Option 3: Hybrid Approach
- **Azure Primary**: Azure Database for PostgreSQL as primary
- **On-Premises Cache**: Local PostgreSQL for failover scenarios
- **Sync Strategy**: Periodic sync when connectivity restored

## Application Architecture Changes

### Current Application Flow:
```
User → App (Azure/OnPrem) → Local Storage (JavaScript localStorage)
```

### Enhanced Application Flow:
```
User → App (Azure/OnPrem) → PostgreSQL Database → Analytics Dashboard
                          ↓
                    Source Tracking (azure/onprem)
```