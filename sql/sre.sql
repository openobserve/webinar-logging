SELECT 
  DATE_TRUNC('hour', CAST(_timestamp / 1000000 AS TIMESTAMP)) as hour_window,
  COUNT(*) as total_events,
  SUM(CASE WHEN log_type = 'access' THEN 1 ELSE 0 END) as access_count,
  SUM(CASE WHEN log_type = 'error' THEN 1 ELSE 0 END) as error_count,
  SUM(CASE WHEN status >= 500 THEN 1 ELSE 0 END) as server_errors,
  SUM(CASE WHEN status >= 400 AND status < 500 THEN 1 ELSE 0 END) as client_errors,
  COUNT(DISTINCT client_ip) as unique_users,
  ROUND(AVG(CASE WHEN bytes_sent IS NOT NULL THEN bytes_sent END), 0) as avg_response_bytes,
  MAX(CASE WHEN bytes_sent IS NOT NULL THEN bytes_sent END) as max_response_bytes,
  ROUND(
    CAST(SUM(CASE WHEN status < 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DOUBLE), 
    2
  ) as success_rate_pct,
  ROUND(
    CAST(SUM(CASE WHEN status >= 500 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DOUBLE), 
    2
  ) as error_rate_pct,
  ROUND(CAST(COUNT(*) AS DOUBLE) / 3600, 1) as requests_per_second,
  CASE 
    WHEN CAST(SUM(CASE WHEN status < 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DOUBLE) < 95 THEN 'SLO_BREACH'
    WHEN SUM(CASE WHEN status >= 500 THEN 1 ELSE 0 END) > 20 THEN 'HIGH_ERRORS'
    WHEN SUM(CASE WHEN log_type = 'error' THEN 1 ELSE 0 END) > 10 THEN 'ERROR_SPIKE'
    WHEN COUNT(*) > 1000 THEN 'HIGH_LOAD'
    ELSE 'HEALTHY'
  END as sre_health_status
FROM apache2_logs 
WHERE _timestamp >= EXTRACT(EPOCH FROM NOW() - INTERVAL '12' HOUR) * 1000000
GROUP BY DATE_TRUNC('hour', CAST(_timestamp / 1000000 AS TIMESTAMP))
HAVING COUNT(*) > 5
ORDER BY hour_window DESC
LIMIT 12;