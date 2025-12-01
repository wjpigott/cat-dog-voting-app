# Deploy PostgreSQL Database to AKS
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("azure", "onprem", "both")]
    [string]$Environment = "azure",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "rg-cat-dog-voting-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "aks-cat-dog-voting"
)

Write-Host "🔧 Deploying PostgreSQL Database" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Green

try {
    if ($Environment -eq "azure" -or $Environment -eq "both") {
        Write-Host "📋 Configuring kubectl for Azure AKS..." -ForegroundColor Cyan
        
        # Get AKS credentials
        $kubeConfigResult = az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to get AKS credentials: $kubeConfigResult" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✅ AKS credentials configured" -ForegroundColor Green
        
        # Create PostgreSQL manifest content
        $postgresManifest = @"
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: default
type: Opaque
stringData:
  POSTGRES_USER: votinguser
  POSTGRES_PASSWORD: secure_password_123
  POSTGRES_DB: voting_app
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  DB_HOST: "postgres-service"
  DB_NAME: "voting_app"
  DB_USER: "votinguser"
  DB_PORT: "5432"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: managed-csi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
  namespace: default
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        - name: POSTGRES_DB
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_DB
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        readinessProbe:
          exec:
            command:
            - sh
            - -c
            - "pg_isready -U votinguser -d voting_app"
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          exec:
            command:
            - sh
            - -c
            - "pg_isready -U votinguser -d voting_app"
          initialDelaySeconds: 60
          periodSeconds: 30
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: default
spec:
  selector:
    app: postgres
  type: ClusterIP
  ports:
  - port: 5432
    targetPort: 5432
    protocol: TCP
"@

        # Write manifest to temp file
        $tempFile = [System.IO.Path]::GetTempFileName() + ".yaml"
        $postgresManifest | Out-File -FilePath $tempFile -Encoding UTF8
        
        Write-Host "📝 Applying PostgreSQL manifest to AKS..." -ForegroundColor Cyan
        
        # Apply the manifest using Azure CLI
        $applyResult = az aks command invoke --resource-group $ResourceGroup --name $ClusterName --command "kubectl apply -f -" --file $tempFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PostgreSQL deployed to AKS successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to deploy PostgreSQL to AKS: $applyResult" -ForegroundColor Red
        }
        
        # Clean up temp file
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        
        # Wait for deployment
        Write-Host "⏳ Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
        
        for ($i = 1; $i -le 12; $i++) {
            Start-Sleep 10
            $podStatus = az aks command invoke --resource-group $ResourceGroup --name $ClusterName --command "kubectl get pods -l app=postgres -o jsonpath='{.items[0].status.phase}'" 2>&1
            
            if ($podStatus -match "Running") {
                Write-Host "✅ PostgreSQL pod is running!" -ForegroundColor Green
                break
            } elseif ($i -eq 12) {
                Write-Host "⚠️ PostgreSQL pod may still be starting. Check manually." -ForegroundColor Yellow
            } else {
                Write-Host "⏳ Still waiting... (attempt $i/12)" -ForegroundColor Yellow
            }
        }
        
        # Initialize database schema
        Write-Host "📊 Initializing database schema..." -ForegroundColor Cyan
        
        $initScript = @"
-- Create votes table
CREATE TABLE IF NOT EXISTS votes (
    id SERIAL PRIMARY KEY,
    vote_choice VARCHAR(10) NOT NULL CHECK (vote_choice IN ('cat', 'dog')),
    vote_source VARCHAR(20) NOT NULL CHECK (vote_source IN ('azure', 'onprem')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_votes_choice ON votes(vote_choice);
CREATE INDEX IF NOT EXISTS idx_votes_source ON votes(vote_source);
CREATE INDEX IF NOT EXISTS idx_votes_timestamp ON votes(timestamp);

-- Create summary view
CREATE OR REPLACE VIEW vote_summary AS
SELECT 
    vote_choice,
    COUNT(*) as total_votes,
    COUNT(CASE WHEN vote_source = 'azure' THEN 1 END) as azure_votes,
    COUNT(CASE WHEN vote_source = 'onprem' THEN 1 END) as onprem_votes,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM votes), 2) as percentage
FROM votes 
GROUP BY vote_choice;

-- Insert test data
INSERT INTO votes (vote_choice, vote_source, ip_address) VALUES 
('cat', 'azure', '52.154.54.110'),
('dog', 'azure', '52.154.54.110'),
('cat', 'onprem', '66.242.207.21')
ON CONFLICT DO NOTHING;

SELECT 'Database initialized successfully!' as status;
"@
        
        $sqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
        $initScript | Out-File -FilePath $sqlFile -Encoding UTF8
        
        $dbInitResult = az aks command invoke --resource-group $ResourceGroup --name $ClusterName --command "kubectl exec deployment/postgres-deployment -- psql -U votinguser -d voting_app -f -" --file $sqlFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Database schema initialized!" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Database init may have issues (this is sometimes normal on first run)" -ForegroundColor Yellow
            Write-Host "Details: $dbInitResult" -ForegroundColor Gray
        }
        
        # Clean up
        Remove-Item $sqlFile -ErrorAction SilentlyContinue
        
        # Show status
        Write-Host "`n📋 PostgreSQL Deployment Summary:" -ForegroundColor Green
        Write-Host "=================================" -ForegroundColor Green
        
        $statusResult = az aks command invoke --resource-group $ResourceGroup --name $ClusterName --command "kubectl get all -l app=postgres" 2>&1
        Write-Host $statusResult
        
        Write-Host "`n🔗 Database Connection Details:" -ForegroundColor Cyan
        Write-Host "Host: postgres-service.default.svc.cluster.local"
        Write-Host "Port: 5432"
        Write-Host "Database: voting_app"
        Write-Host "Username: votinguser"
        Write-Host "Password: secure_password_123"
        
    }
    
    Write-Host "`n🎉 PostgreSQL deployment completed!" -ForegroundColor Green
    Write-Host "`n💡 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Update voting applications to connect to this database"
    Write-Host "2. Test database connectivity from your applications"
    Write-Host "3. Deploy enhanced voting app with database integration"

} catch {
    Write-Host "❌ Error during PostgreSQL deployment: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}