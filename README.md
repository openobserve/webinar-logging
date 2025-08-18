# OpenTelemetry + OpenObserve High Volume Log Demo

This demo generates high-volume Apache logs using flog, processes them with OpenTelemetry Collector, and visualizes them in OpenObserve with custom parsing and dashboards.

## Prerequisites

- Ubuntu 20.04 or later
- Root or sudo access
- Internet connectivity
- OpenObserve account (cloud or self-hosted)

## Directory Structure

```
webinar-demo/
├── docker/
│   ├── docker_setup.sh
│   └── docker-compose.yml
├── otel/
│   └── otel-config.yaml
├── vrl/
│   └── apache-parsing-functions.vrl
├── pipelines/
│   └── apache-log-pipeline.json
└── README.md
```

## Step 1: Setup Docker

Navigate to the docker directory and run the setup script:

```bash
cd docker/
chmod +x docker_setup.sh
./docker_setup.sh
```

**Important**: Log out and log back in after Docker installation for group changes to take effect.

Test Docker installation:
```bash
docker run hello-world
docker-compose --version
```

## Step 2: Deploy Log Generators

Copy the docker-compose.yml file to your project directory:

```bash
# From the docker/ directory
cp docker-compose.yml ../
cd ..
```

Create logs directory and start containers:
```bash
mkdir -p /tmp/logs
docker-compose up -d
```

Check container status:
```bash
docker-compose ps
```

## Step 3: Validate Log Generation

Verify logs are being generated at high volume:

```bash
# Check log files exist and are growing
ls -lrth /tmp/logs/

# Monitor real-time log generation
watch -n 2 'ls -lh /tmp/apache/ && echo "=== Log Counts ===" && wc -l /tmp/logs/*.log'

# View sample logs
tail -f /tmp/logs/apache_combined.log
```

Expected output:
- **apache_common.log**: ~1,000 logs/second
- **apache_combined.log**: ~12,500 logs/second  
- **apache_error.log**: ~160 logs/second
- **Total**: ~13,660 logs/second

## Step 4: Install OpenTelemetry Collector

Follow the official OpenObserve documentation for installing OpenTelemetry Collector on Ubuntu:

1. Visit [OpenObserve Documentation](https://openobserve.ai/docs/)
2. Navigate to "Data Sources" → "OpenTelemetry"
3. Follow the Ubuntu installation steps
4. Stop the collector service before configuration:
   ```bash
   sudo systemctl stop otel-collector
   ```

## Step 5: Configure OpenTelemetry Collector

Replace the default OTel configuration with the provided config:

```bash
# Backup existing config
sudo cp /etc/otel-collector/config.yaml /etc/otel-collector/config.yaml.backup

# Copy new configuration
sudo cp otel/otel-config.yaml /etc/otel-collector/config.yaml

# Update the configuration with your OpenObserve details
sudo nano /etc/otel-collector/config.yaml
```

**Required updates in config.yaml:**
- Replace `YOUR_OPENOBSERVE_ENDPOINT` with your OpenObserve URL
- Replace `YOUR_BASE64_CREDENTIALS` with base64(username:password)
- Update log file paths if different from `/tmp/apache/`

To generate base64 credentials:
```bash
echo -n 'your_username:your_password' | base64
```

## Step 6: Start OpenTelemetry Collector

Restart the OTel Collector with new configuration:

```bash
# Start the service
sudo systemctl start otel-collector
sudo systemctl enable otel-collector

# Check status
sudo systemctl status otel-collector

# Monitor logs for any errors
sudo journalctl -u otel-collector -f
```

Verify logs are being processed:
```bash
# Check for successful log ingestion
sudo journalctl -u otel-collector --since "5 minutes ago" | grep -i "successfully sent"
```

## Step 7: Add VRL Parsing Functions

In OpenObserve web interface:

1. Navigate to **Functions** section
2. Click **Add Function**
3. Copy content from `vrl/apache-parsing-functions.vrl`
4. Create function with name: `apache_log_parser`
5. Save the function

The VRL functions will:
- Parse Apache Common and Combined log formats
- Extract HTTP status categories (2xx, 3xx, 4xx, 5xx)
- Convert response sizes to integers
- Add geo-location data for IP addresses
- Extract browser and OS information from user agents

## Step 8: Upload Processing Pipeline

1. In OpenObserve, go to **Pipelines** section
2. Click **Import Pipeline**
3. Upload the file `pipelines/apache-log-pipeline.json`
4. Associate the pipeline with your `apache_logs` stream
5. Enable the pipeline

The pipeline will automatically apply the VRL parsing functions to incoming logs.

## Step 9: Validate Log Parsing

Check that logs are being parsed correctly:

1. Go to **Logs** section in OpenObserve
2. Select the `apache_logs` stream
3. Verify parsed fields are present:
   - `http_status_category`
   - `response_size_int`
   - `request_method`
   - `user_agent_browser`
   - `geo_country`
   - etc.


### Common Issues

**OTel Collector not reading logs:**
```bash
# Check file permissions
ls -la /tmp/logs/
sudo chown otel-collector:otel-collector /tmp/logs/*.log

# Verify config syntax
sudo /usr/local/bin/otelcol-contrib --config=/etc/otel-collector/config.yaml --dry-run
```

**High CPU usage:**
```bash
# Reduce log generation if needed
docker-compose down
# Edit docker-compose.yml to reduce -d values or increase -s values
docker-compose up -d
```

**OpenObserve connection issues:**
```bash
# Test connectivity
curl -X POST "https://api.openobserve.ai/api/your_org/default/v1/logs" \
     -H "Authorization: Basic YOUR_BASE64_CREDENTIALS" \
     -H "Content-Type: application/json" \
     -d '{"test": "message"}'
```

## Performance Metrics

Expected throughput:
- **Log Generation**: ~13,660 logs/second
- **OTel Processing**: ~820,000 logs/minute
- **OpenObserve Ingestion**: Depends on plan/instance size
- **Dashboard Refresh**: Real-time (sub-second)

## Cleanup

To stop and remove all components:

```bash
# Stop log generators
docker-compose down

# Stop OTel Collector
sudo systemctl stop otel-collector

# Remove log files
sudo rm -rf /tmp/apache/

# Remove Docker images (optional)
docker system prune -f
```

## Support

For issues:
1. Check OTel Collector logs: `sudo journalctl -u otel-collector -f`
2. Check Docker container logs: `docker-compose logs`
3. Verify OpenObserve connectivity and credentials
4. Monitor system resources for bottlenecks