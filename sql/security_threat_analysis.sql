-- Security Threat Analysis - IP Threat Detection with Geographic Data
SELECT 
  client_ip,
  COALESCE(geo_city_country_name, 'Unknown') as country,
  COALESCE(geo_asn_autonomous_system_organization, 'Unknown ISP') as isp_organization,
  COUNT(*) as total_requests,
  SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) as failed_requests,
  SUM(CASE WHEN status = 404 THEN 1 ELSE 0 END) as scan_attempts,
  SUM(CASE WHEN status = 502 THEN 1 ELSE 0 END) as gateway_errors,
  SUM(CASE WHEN method = 'POST' THEN 1 ELSE 0 END) as post_requests,
  COUNT(DISTINCT url) as unique_urls,
  ROUND(
    CAST(SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DOUBLE), 
    1
  ) as error_rate_pct,
  CASE 
    WHEN SUM(CASE WHEN status = 404 THEN 1 ELSE 0 END) > 10 THEN 'SCANNER'
    WHEN CAST(SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DOUBLE) > 50 THEN 'HIGH_RISK'
    WHEN COUNT(*) > 50 AND SUM(CASE WHEN method = 'POST' THEN 1 ELSE 0 END) > 10 THEN 'BRUTE_FORCE'
    WHEN COUNT(*) > 100 THEN 'HIGH_VOLUME'
    ELSE 'NORMAL'
  END as threat_level
FROM apache2_logs 
WHERE _timestamp >= EXTRACT(EPOCH FROM NOW() - INTERVAL '6' HOUR) * 1000000
GROUP BY client_ip, geo_city_country_name, geo_asn_autonomous_system_organization
HAVING COUNT(*) > 5
ORDER BY 
  CASE threat_level 
    WHEN 'SCANNER' THEN 1
    WHEN 'HIGH_RISK' THEN 2
    WHEN 'BRUTE_FORCE' THEN 3
    WHEN 'HIGH_VOLUME' THEN 4
    ELSE 5
  END,
  total_requests DESC
LIMIT 25;