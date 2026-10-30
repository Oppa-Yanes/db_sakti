-- Ringkasan per SPB
WITH spb AS (
  SELECT id, transport_nbr, transport_date, estate_id, total_bunch, total_loose_fruit, create_by
  FROM trx.t_transport
  WHERE transport_date >= '2026-10-01' AND transport_date < '2026-10-30'  -- ganti
    AND estate_id = 14                                                  
),
rel AS (
  SELECT r.transport_id,
         COUNT(*)                                                         AS rel_rows,
         COUNT(*) FILTER (WHERE r.harvest_id IS NULL)                     AS rel_harvest_id_null,
         COUNT(*) FILTER (WHERE r.harvest_id IS NOT NULL AND h.id IS NULL) AS bcc_hilang,
         COUNT(*) FILTER (WHERE h.id IS NOT NULL AND h.transport_id IS NULL) AS bcc_transport_null,
         COUNT(*) FILTER (WHERE h.transport_id <> r.transport_id)         AS bcc_ke_spb_lain
  FROM trx.t_transport_harvest_rel r
  JOIN spb ON spb.id = r.transport_id
  LEFT JOIN trx.t_harvest h ON h.id = r.harvest_id
  GROUP BY r.transport_id
),
hv AS (
  SELECT h.transport_id, COUNT(*) AS bcc, SUM(h.bunch_qty) AS janjang, SUM(h.loose_fruit_qty) AS brondolan
  FROM trx.t_harvest h
  JOIN spb ON spb.id = h.transport_id
  GROUP BY h.transport_id
)
SELECT spb.transport_nbr, spb.transport_date, spb.create_by,
       spb.total_bunch, spb.total_loose_fruit,
       COALESCE(rel.rel_rows, 0)            AS rel_rows,
       COALESCE(hv.bcc, 0)                  AS bcc_di_server,
       COALESCE(rel.bcc_hilang, 0)          AS bcc_hilang,
       COALESCE(rel.rel_harvest_id_null, 0) AS rel_harvest_id_null,
       COALESCE(rel.bcc_transport_null, 0)  AS bcc_transport_null,
       COALESCE(rel.bcc_ke_spb_lain, 0)     AS bcc_ke_spb_lain,
       spb.total_bunch       - COALESCE(hv.janjang, 0)   AS selisih_janjang,
       spb.total_loose_fruit - COALESCE(hv.brondolan, 0) AS selisih_brondolan
FROM spb
LEFT JOIN rel ON rel.transport_id = spb.id
LEFT JOIN hv  ON hv.transport_id  = spb.id
WHERE COALESCE(hv.bcc, 0) = 0
   OR COALESCE(rel.bcc_hilang, 0) > 0
   OR COALESCE(rel.rel_harvest_id_null, 0) > 0
   OR COALESCE(rel.bcc_transport_null, 0) > 0
   OR COALESCE(rel.bcc_ke_spb_lain, 0) > 0
   OR spb.total_bunch <> COALESCE(hv.janjang, 0)
ORDER BY spb.transport_date, spb.transport_nbr;

-- Daftar BCC yang hilang (ada di relay, tidak ada di `t_harvest`)
SELECT t.transport_nbr, t.transport_date, r.harvest_id, r.location_id, tl.block_code,
       r.profile_id, r.create_by, r.create_date
FROM trx.t_transport t
JOIN trx.t_transport_harvest_rel r ON r.transport_id = t.id
LEFT JOIN trx.t_harvest h ON h.id = r.harvest_id
LEFT JOIN trx.t_location tl ON tl.id = r.location_id
WHERE t.transport_date >= '2026-10-01' AND t.transport_date < '2026-10-30' 
  AND t.estate_id = 15                                           
  AND r.harvest_id IS NOT NULL
  AND h.id IS NULL
ORDER BY t.transport_nbr, r.create_date;




