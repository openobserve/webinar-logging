SELECT 
  url as endpoint,
  COALESCE(method, 'UNKNOWN') as http_method,
  COUNT(*) as total_requests,
  COUNT(DISTINCT client_ip) as unique_visitors,
  COUNT(DISTINCT COALESCE(geo_city_country_name, 'Unknown')) as countries,
  SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) as error_requests,
  SUM(CASE WHEN status = 404 THEN 1 ELSE 0 END) as not_found_hits,
  SUM(CASE WHEN status = 502 THEN 1 ELSE 0 END) as gateway_errors,
  SUM(CASE WHEN status >= 500 THEN 1 ELSE 0 END) as server_errors,
  ROUND(AVG(CASE WHEN bytes_sent IS NOT NULL THEN bytes_sent END), 0) as avg_response_bytes,
  MAX(CASE WHEN bytes_sent IS NOT NULL THEN bytes_sent END) as max_response_bytes,
  ROUND(
    CAST(SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DOUBLE), 
    1
  ) as error_rate_pct,
  CASE 
    WHEN url LIKE '%web%' OR url LIKE '%service%' THEN 'WEB_SERVICE'
    WHEN url LIKE '%api%' OR url LIKE '%engage%' THEN 'API_ENDPOINT'
    WHEN url LIKE '%admin%' OR url LIKE '%config%' THEN 'ADMIN_AREA'
    WHEN url LIKE '%transform%' OR url LIKE '%iterate%' THEN 'PROCESSING_ENDPOINT'
    WHEN url LIKE '%unleash%' OR url LIKE '%convergence%' THEN 'BUSINESS_LOGIC'
    ELSE 'GENERAL_ENDPOINT'
  END as endpoint_category,
  CASE 
    WHEN COUNT(DISTINCT client_ip) > 10 AND SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) > 5 THEN 'UNDER_ATTACK'
    WHEN SUM(CASE WHEN status = 404 THEN 1 ELSE 0 END) > 3 THEN 'SCAN_TARGET'
    WHEN COUNT(*) > 20 AND COUNT(DISTINCT client_ip) > 5 THEN 'HIGH_INTEREST'
    WHEN SUM(CASE WHEN status >= 500 THEN 1 ELSE 0 END) > 0 THEN 'UNSTABLE'
    ELSE 'NORMAL'
  END as security_status,
  ROUND(
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DOUBLE), 
    2
  ) as traffic_share_pct
FROM apache2_logs 
WHERE _timestamp >= EXTRACT(EPOCH FROM NOW() - INTERVAL '6' HOUR) * 1000000
  AND url IS NOT NULL
  AND log_type = 'access'
GROUP BY url, method
HAVING COUNT(*) >= 2
ORDER BY 
  CASE security_status 
    WHEN 'UNDER_ATTACK' THEN 1
    WHEN 'SCAN_TARGET' THEN 2
    WHEN 'UNSTABLE' THEN 3
    WHEN 'HIGH_INTEREST' THEN 4
    ELSE 5
  END,
  total_requests DESC
LIMIT 2000;