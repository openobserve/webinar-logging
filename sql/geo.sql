SELECT 
  geo_city_country_name as country,
  geo_city_continent_code as continent,
  log_type,
  COUNT(*) as total_events,
  SUM(CASE WHEN log_type = 'error' THEN 1 ELSE 0 END) as error_count,
  SUM(CASE WHEN log_type = 'access' AND status >= 400 THEN 1 ELSE 0 END) as http_errors,
  COUNT(DISTINCT client_ip) as unique_ips,
  ROUND(AVG(CASE WHEN log_type = 'access' THEN bytes_sent ELSE NULL END), 0) as avg_response_size,
  ROUND(
    CAST(SUM(CASE WHEN log_type = 'error' OR (log_type = 'access' AND status >= 400) THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DOUBLE), 
    2
  ) as error_rate_percent
FROM apache2_logs 
WHERE _timestamp >= EXTRACT(EPOCH FROM NOW() - INTERVAL '6' HOUR) * 1000000
GROUP BY geo_city_country_name, geo_city_continent_code, log_type
HAVING COUNT(*) > 10
ORDER BY error_rate_percent DESC, total_events DESC
LIMIT 20;