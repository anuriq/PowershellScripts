SELECT hsr.host_host_id AS host_id
     , s.service_id
     , s.service_description
     , s.service_normal_check_interval * 60 AS check_interval
     , s.service_retry_check_interval * 60 AS retry_interval
     , s.service_max_check_attempts AS check_attempts
FROM
  service AS s
JOIN host_service_relation AS hsr
ON hsr.service_service_id = s.service_id
WHERE
  s.service_activate = '1'
  AND hsr.host_host_id IS NOT NULL
UNION
SELECT hgr.host_host_id AS host_id
     , s.service_id
     , s.service_description
     , s.service_normal_check_interval * 60 AS check_interval
     , s.service_retry_check_interval * 60 AS retry_interval
     , s.service_max_check_attempts AS check_attempts
FROM
  service AS s
JOIN host_service_relation AS hsr
ON hsr.service_service_id = s.service_id
JOIN hostgroup_relation AS hgr
ON hsr.hostgroup_hg_id = hgr.hostgroup_hg_id
WHERE
  hsr.hostgroup_hg_id IS NOT NULL
  AND s.service_activate = '1'
