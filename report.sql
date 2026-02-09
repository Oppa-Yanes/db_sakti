-- report monitong SAKTI
WITH params AS (
	SELECT 
		'20260209' current_date
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
	loc.block_code,
	loc.is_carry_over,
	loc.harvest_area_target rkh_harvest_area,
	COALESCE(bkm.harvest_area_bkm, 0) bkm_harvest_area,
	COALESCE(bcc.counter, 0) bcc_cnt,
	COALESCE(spb.counter, 0) spb_cnt,
	loc.est_weight rkh_weight,
	COALESCE(bcc.bunch_qty, 0) * (loc.est_weight / loc.est_bunch) bcc_weight,
	COALESCE(spb.bunch_qty, 0) * (loc.est_weight / loc.est_bunch) spb_weight,
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
	rkh.stage = 'C'
	AND TO_CHAR(rkh.rkh_date, 'YYYYMMDD') = p.current_date
ORDER BY
	rkh.rkh_nbr,
	loc.block_code
;

