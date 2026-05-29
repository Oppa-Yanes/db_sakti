-- report monitong SAKTI
-- https://pijar.gbs.id/operational/harvest-monitoring
WITH params AS (
	SELECT 
		'20260211' current_date
),
hk_act AS (
	WITH attendance AS (
		SELECT
			fore.rkh_id,
			harv.nip harvester_nip,
			harv.name harvester,
			foreg.code foreman_code,
			foreg.name foreman_name
		FROM 
			t_harvester harv
			LEFT JOIN t_foreman fore ON fore.id = harv.foreman_id
			LEFT JOIN m_foreman_group foreg ON foreg.id = fore.foreman_group_id 
	)
	SELECT
		att.rkh_id,
		COUNT(att.*) act_hk
	FROM 
		attendance att
	GROUP BY
		att.rkh_id
),
hk_est AS (
	SELECT
		loc.rkh_id,
		SUM(loc.est_hk) est_hk
	FROM
		t_location loc
	GROUP BY
		loc.rkh_id
),
bcc AS (
	SELECT
		hv.location_id,
		COUNT(hv.*) counter,
		SUM(hv.bunch_qty) bunch_qty,
		SUM(hv.bunch_qty - hv.unripe_qty - hv.rotten_empty_bunch_qty) ripe_qty,
		SUM(hv.unripe_qty) unripe_qty,
		SUM(hv.rotten_empty_bunch_qty) rotten_empty_bunch_qty,
		SUM(hv.loose_fruit_qty) loose_fruit_qty,
		SUM(hv.abnormal_01_qty) abnormal_01_qty,
		SUM(hv.abnormal_02_qty) abnormal_02_qty,
		SUM(hv.abnormal_03_qty) abnormal_03_qty,
		SUM(hv.abnormal_04_qty) abnormal_04_qty,
		SUM(hv.abnormal_05_qty) abnormal_05_qty
	FROM 
		t_harvest hv
	GROUP BY
		hv.location_id
),
spb AS (
	SELECT
		hv.location_id,
		COUNT(hv.*) counter,
		SUM(hv.bunch_qty) bunch_qty,
		SUM(hv.bunch_qty - hv.unripe_qty - hv.rotten_empty_bunch_qty) ripe_qty,
		SUM(hv.unripe_qty) unripe_qty,
		SUM(hv.rotten_empty_bunch_qty) rotten_empty_bunch_qty,
		SUM(hv.loose_fruit_qty) loose_fruit_qty,
		SUM(hv.abnormal_01_qty) abnormal_01_qty,
		SUM(hv.abnormal_02_qty) abnormal_02_qty,
		SUM(hv.abnormal_03_qty) abnormal_03_qty,
		SUM(hv.abnormal_04_qty) abnormal_04_qty,
		SUM(hv.abnormal_05_qty) abnormal_05_qty
	FROM 
		t_transport tr
		LEFT JOIN t_harvest hv ON hv.transport_id = tr.id
	GROUP BY
		hv.location_id
),
bkm AS (
	SELECT
		bkm.location_id,
		SUM(bkm.ha_amt) harvest_area_bkm
	FROM
		t_bkm bkm
	GROUP BY
		bkm.location_id
)
SELECT
	rkh.rkh_nbr,
	rkh.rkh_date,
	rkh.create_by rkh_user,
	rkh.stage rkh_stage,
	loc.block_code,
	loc.is_carry_over,
	loc.harvest_area_target rkh_harvest_area,
	COALESCE(bkm.harvest_area_bkm, 0) bkm_harvest_area,
	COALESCE(bcc.counter, 0) bcc_cnt,
	COALESCE(spb.counter, 0) spb_cnt,
	loc.est_weight rkh_weight,
	COALESCE(bcc.bunch_qty * (loc.est_weight / NULLIF(loc.est_bunch, 0)), 0) bcc_weight,
	COALESCE(spb.bunch_qty * (loc.est_weight / NULLIF(loc.est_bunch, 0)), 0) spb_weight,
	loc.est_bunch rkh_bunch,
	COALESCE(bcc.bunch_qty, 0) bcc_bunch,
	COALESCE(spb.bunch_qty, 0) spb_bunch,
	hk_est.est_hk rkh_hk,
	hk_act.act_hk bcc_hk
FROM
	t_rkh rkh 
	LEFT JOIN hk_est ON hk_est.rkh_id = rkh.id
	LEFT JOIN hk_act ON hk_act.rkh_id = rkh.id
	LEFT JOIN t_location loc ON loc.rkh_id = rkh.id
	LEFT JOIN bcc ON bcc.location_id = loc.id
	LEFT JOIN spb ON spb.location_id = loc.id
	LEFT JOIN bkm ON bkm.location_id = loc.id
	LEFT JOIN m_company coy ON coy.id = rkh.company_id 
	LEFT JOIN m_division div ON div.id = rkh.division_id 
	JOIN params p ON TRUE
WHERE
	TO_CHAR(rkh.rkh_date, 'YYYYMMDD') = p.current_date
ORDER BY
	rkh.rkh_nbr,
	loc.block_code
;

-- Laporan Akurasi ODOO vs SAKTI per Pemanen
-- URL:
WITH params AS (
    SELECT
    	'20260511' AS start_date,
    	'20260511' AS end_date,    	
    	1 AS company_id,
    	14 AS estate_id,
    	--NULL::INT AS estate_id,
    	NULL::INT AS division_id
    	--63 AS division_id
),
odoo AS (
	SELECT
		hv.date::DATE harvest_date,
		batch.company_id,
		batch.estate_id,
		dept.division_id,
		batch.foreman_group_id,
		batch.kerani_id kerani_harvest_id,
		hv.employee_id emp_id,
		COALESCE(SUM(hv.harvest_area), 0) ha_qty,
		COALESCE(SUM(hv.bunches_qty), 0) jjg_qty,
		COALESCE(SUM(hv.loose_qty), 0) brd_qty
	FROM
		plantation_harvest hv
		LEFT JOIN plantation_batch_harvest batch ON batch.id = hv.harvest_batch_id 
		LEFT JOIN hr_foreman_group fg ON fg.id = batch.foreman_group_id 
		LEFT JOIN hr_department dept ON dept.id = fg.department_id 
		JOIN params p ON TRUE
	WHERE
		--batch.state = 'done'
		batch.company_id = p.company_id 
		AND (p.estate_id IS NULL OR batch.estate_id = p.estate_id)
		AND (p.division_id IS NULL OR dept.division_id = p.division_id)
		AND TO_CHAR(batch.date, 'YYYYMMDD') BETWEEN p.start_date AND p.end_date 
	GROUP BY
		hv.date,
		batch.company_id,
		batch.estate_id,
		dept.division_id,
		batch.foreman_group_id,
		batch.kerani_id,
		hv.employee_id	
),
sakti AS (
	SELECT
		hv.harvest_date::DATE harvest_date,
		rkh.company_id,
		rkh.estate_id,
		rkh.division_id,
		batch.foreman_group_id,
		batch.kerani_harvest_id,
		hvt.emp_id,
		COALESCE(bkm.ha_qty, 0) ha_qty,
		COALESCE(SUM(hv.bunch_qty), 0) jjg_qty,
		COALESCE(SUM(hv.loose_fruit_qty), 0) brd_qty
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvt ON hvt.sakti_id = hv.harvester_id
		LEFT JOIN sakti_foreman batch ON batch.sakti_id = hvt.foreman_id
		LEFT JOIN sakti_rkh rkh ON rkh.sakti_id = batch.rkh_id
		LEFT JOIN (
			SELECT
				bkm.harvester_id,
				COALESCE(SUM(bkm.ha_amt), 0) ha_qty
			FROM
				sakti_bkm bkm
			GROUP BY
				bkm.harvester_id 
			) bkm ON bkm.harvester_id = hvt.sakti_id
		JOIN params p ON TRUE
	WHERE
		rkh.company_id = p.company_id 
		AND (p.estate_id IS NULL OR rkh.estate_id = p.estate_id)
		AND (p.division_id IS NULL OR rkh.division_id = p.division_id)
		AND TO_CHAR(hv.harvest_date, 'YYYYMMDD') BETWEEN p.start_date AND p.end_date 
	GROUP BY
		hv.harvest_date::DATE,
		rkh.company_id,
		rkh.estate_id,
		rkh.division_id,
		batch.foreman_group_id,
		batch.kerani_harvest_id,
		hvt.emp_id,
		bkm.ha_qty
)
SELECT
    COALESCE(odoo.harvest_date, sakti.harvest_date) harvest_date,
    COALESCE(odoo.company_id, sakti.company_id) company_id,
    coy.name company_name,
    COALESCE(odoo.estate_id, sakti.estate_id) estate_id,
    est.name estate_name,
    COALESCE(odoo.division_id, sakti.division_id) division_id,
    div.name division_name,
    COALESCE(odoo.foreman_group_id, sakti.foreman_group_id) foreman_group_id,
    fg.name foreman_group,
    mandor.id foreman_id,
    mandor.name foreman_name,
    kerani.id kerani_id,
    kerani.name kerani_name,
    COALESCE(odoo.emp_id, sakti.emp_id) harvester_id,
    harvester.name harvester_name,
    harvester.nomor_induk_pegawai harvester_nip,
    COALESCE(odoo.ha_qty, 0) odoo_ha_qty,
    COALESCE(sakti.ha_qty, 0) sakti_ha_qty,
    COALESCE(sakti.ha_qty / NULLIF(odoo.ha_qty, 0), 0) ha_acc,
    COALESCE(odoo.jjg_qty, 0) odoo_jjg_qty,
    COALESCE(sakti.jjg_qty, 0) sakti_jjg_qty,
    COALESCE(sakti.jjg_qty / NULLIF(odoo.jjg_qty, 0), 0) jjg_acc,
    COALESCE(odoo.brd_qty, 0) odoo_brd_qty,
    COALESCE(sakti.brd_qty, 0) sakti_brd_qty,
    COALESCE(sakti.brd_qty / NULLIF(odoo.brd_qty, 0), 0) brd_acc
FROM
	odoo
	FULL JOIN sakti ON sakti.emp_id = odoo.emp_id
	LEFT JOIN res_company coy ON coy.id = COALESCE(odoo.company_id, sakti.company_id)
	LEFT JOIN plantation_estate est ON est.id = COALESCE(odoo.estate_id, sakti.estate_id)
	LEFT JOIN plantation_division div ON div.id = COALESCE(odoo.division_id, sakti.division_id)
	LEFT JOIN hr_foreman_group fg ON fg.id = COALESCE(odoo.foreman_group_id, sakti.foreman_group_id)
	LEFT JOIN hr_employee mandor ON mandor.id = fg.foreman_id 
	LEFT JOIN hr_employee kerani ON kerani.id = fg.kerani_harvest_id 
	LEFT JOIN hr_employee harvester ON harvester.id = COALESCE(odoo.emp_id, sakti.emp_id)
;

-- Laporan Akurasi ODOO vs SAKTI per Kerani Panen
-- URL:
WITH params AS (
    SELECT
    	'20260501' AS start_date,
    	'20260519' AS end_date,    	
    	1 AS company_id,
    	14 AS estate_id,
    	--NULL::INT AS estate_id,
    	NULL::INT AS division_id
    	--63 AS division_id
),
odoo AS (
	SELECT
		hv.date::DATE harvest_date,
		batch.company_id,
		batch.estate_id,
		dept.division_id,
		batch.foreman_group_id,
		batch.kerani_id kerani_harvest_id,
		hv.employee_id harvester_id,
		COALESCE(SUM(hv.harvest_area), 0) ha_qty,
		COALESCE(SUM(hv.bunches_qty), 0) jjg_qty,
		COALESCE(SUM(hv.loose_qty), 0) brd_qty
	FROM
		plantation_harvest hv
		LEFT JOIN plantation_batch_harvest batch ON batch.id = hv.harvest_batch_id 
		LEFT JOIN hr_foreman_group fg ON fg.id = batch.foreman_group_id 
		LEFT JOIN hr_department dept ON dept.id = fg.department_id 
		JOIN params p ON TRUE
	WHERE
		--batch.state = 'done'
		batch.company_id = p.company_id 
		AND (p.estate_id IS NULL OR batch.estate_id = p.estate_id)
		AND (p.division_id IS NULL OR dept.division_id = p.division_id)
		AND TO_CHAR(batch.date, 'YYYYMMDD') BETWEEN p.start_date AND p.end_date 
	GROUP BY
		hv.date,
		batch.company_id,
		batch.estate_id,
		dept.division_id,
		batch.foreman_group_id,
		batch.kerani_id,
		hv.employee_id	
),
sakti AS (
	SELECT
		hv.harvest_date::DATE harvest_date,
		rkh.company_id,
		rkh.estate_id,
		rkh.division_id,
		batch.foreman_group_id,
		batch.kerani_harvest_id,
		hvt.emp_id harvester_id,
		COALESCE(bkm.ha_qty, 0) ha_qty,
		COALESCE(SUM(hv.bunch_qty), 0) jjg_qty,
		COALESCE(SUM(hv.loose_fruit_qty), 0) brd_qty
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvt ON hvt.sakti_id = hv.harvester_id
		LEFT JOIN sakti_foreman batch ON batch.sakti_id = hvt.foreman_id
		LEFT JOIN sakti_rkh rkh ON rkh.sakti_id = batch.rkh_id
		LEFT JOIN (
			SELECT
				bkm.harvester_id,
				COALESCE(SUM(bkm.ha_amt), 0) ha_qty
			FROM
				sakti_bkm bkm
			GROUP BY
				bkm.harvester_id 
			) bkm ON bkm.harvester_id = hvt.sakti_id
		JOIN params p ON TRUE
	WHERE
		rkh.company_id = p.company_id 
		AND (p.estate_id IS NULL OR rkh.estate_id = p.estate_id)
		AND (p.division_id IS NULL OR rkh.division_id = p.division_id)
		AND TO_CHAR(hv.harvest_date, 'YYYYMMDD') BETWEEN p.start_date AND p.end_date 
	GROUP BY
		hv.harvest_date::DATE,
		rkh.company_id,
		rkh.estate_id,
		rkh.division_id,
		batch.foreman_group_id,
		batch.kerani_harvest_id,
		hvt.emp_id,
		bkm.ha_qty
),
result_set AS (
	SELECT
	    COALESCE(odoo.harvest_date, sakti.harvest_date) harvest_date,
	    COALESCE(odoo.company_id, sakti.company_id) company_id,
	    coy.name company_name,
	    COALESCE(odoo.estate_id, sakti.estate_id) estate_id,
	    est.name estate_name,
	    COALESCE(odoo.division_id, sakti.division_id) division_id,
	    div.name division_name,
	    COALESCE(odoo.foreman_group_id, sakti.foreman_group_id) foreman_group_id,
	    fg.name foreman_group,
	    mandor.id foreman_id,
	    mandor.name foreman_name,
	    kerani.id kerani_id,
	    kerani.name kerani_name,
	    COALESCE(odoo.harvester_id, sakti.harvester_id) harvester_id,
	    harvester.name harvester_name,
	    harvester.nomor_induk_pegawai harvester_nip,
	    COALESCE(odoo.ha_qty, 0) odoo_ha_qty,
	    COALESCE(sakti.ha_qty, 0) sakti_ha_qty,
	    COALESCE(sakti.ha_qty / NULLIF(odoo.ha_qty, 0), 0) ha_acc,
	    COALESCE(odoo.jjg_qty, 0) odoo_jjg_qty,
	    COALESCE(sakti.jjg_qty, 0) sakti_jjg_qty,
	    COALESCE(sakti.jjg_qty / NULLIF(odoo.jjg_qty, 0), 0) jjg_acc,
	    COALESCE(odoo.brd_qty, 0) odoo_brd_qty,
	    COALESCE(sakti.brd_qty, 0) sakti_brd_qty,
	    COALESCE(sakti.brd_qty / NULLIF(odoo.brd_qty, 0), 0) brd_acc
	FROM
		odoo
		FULL JOIN sakti ON sakti.harvester_id = odoo.harvester_id
		LEFT JOIN res_company coy ON coy.id = COALESCE(odoo.company_id, sakti.company_id)
		LEFT JOIN plantation_estate est ON est.id = COALESCE(odoo.estate_id, sakti.estate_id)
		LEFT JOIN plantation_division div ON div.id = COALESCE(odoo.division_id, sakti.division_id)
		LEFT JOIN hr_foreman_group fg ON fg.id = COALESCE(odoo.foreman_group_id, sakti.foreman_group_id)
		LEFT JOIN hr_employee mandor ON mandor.id = fg.foreman_id 
		LEFT JOIN hr_employee kerani ON kerani.id = fg.kerani_harvest_id 
		LEFT JOIN hr_employee harvester ON harvester.id = COALESCE(odoo.harvester_id, sakti.harvester_id)
)
SELECT
	rs.harvest_date,
	rs.company_id,
	rs.company_name,
	rs.estate_id,
	rs.estate_name,
	rs.division_id,
	rs.division_name,
	rs.foreman_group_id,
	rs.foreman_group,
	rs.foreman_name,
	rs.kerani_id,
	rs.kerani_name,
	rs.harvester_id,
	rs.harvester_name,
	SUM(rs.odoo_ha_qty) odoo_ha_qty,
	SUM(rs.sakti_ha_qty) sakti_ha_qty,
	SUM(rs.odoo_jjg_qty) odoo_jjg_qty,
	SUM(rs.sakti_jjg_qty) sakti_jjg_qty,
	SUM(rs.odoo_brd_qty) odoo_brd_qty,
	SUM(rs.sakti_brd_qty) sakti_brd_qty,
	GREATEST((1 - (ABS(SUM(rs.sakti_ha_qty) - SUM(rs.odoo_ha_qty)) / NULLIF(SUM(rs.odoo_ha_qty), 0))), 0) AS ha_acc,
	GREATEST((1 - (ABS(SUM(rs.sakti_jjg_qty) - SUM(rs.odoo_jjg_qty)) / NULLIF(SUM(rs.odoo_jjg_qty), 0))), 0) AS jjg_acc,
	GREATEST((1 - (ABS(SUM(rs.sakti_brd_qty) - SUM(rs.odoo_brd_qty)) / NULLIF(SUM(rs.odoo_brd_qty), 0))), 0) AS brd_acc
FROM
	result_set rs
GROUP BY
	rs.harvest_date,
	rs.company_id,
	rs.company_name,
	rs.estate_id,
	rs.estate_name,
	rs.division_id,
	rs.division_name,
	rs.foreman_group_id,
	rs.foreman_group,
	rs.foreman_name,
	rs.kerani_id,
	rs.kerani_name,
	rs.harvester_id,
	rs.harvester_name
 ORDER BY
 	rs.harvest_date,
	rs.company_name,
	rs.estate_name,
	rs.division_name,
	rs.foreman_group,
	rs.foreman_name,
	rs.kerani_name,
	rs.harvester_name
;
