-- Hasil Panen - Header
WITH params AS (
	SELECT
		DATE '2026-03-09' current_date
),
holiday AS (
	SELECT (
		EXTRACT(DOW FROM p.current_date) = 0
		OR EXISTS (
			SELECT 1 
			FROM gbs_hr_holiday_line hl 
			WHERE hl.date = p.current_date)
		) AS is_holiday
	FROM
		params p
),
block_agg AS (
	SELECT
		hvr.foreman_id,
		hv.harvest_date::DATE harvest_date,
		STRING_AGG(DISTINCT loc.block_id::TEXT, ', ') planted_block_ids
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvr ON hvr.id = hv.harvester_id
		LEFT JOIN sakti_location loc ON loc.id = hv.location_id
	GROUP BY
		hvr.foreman_id,
		hv.harvest_date::DATE
)
SELECT
	batch.id batch_id,
	rkh.rkh_date date,
	h.is_holiday,
	bagg.planted_block_ids,
	--f.is_kutip_required,
	batch.foreman_group_id,
	batch.foreman_id,
	batch.foreman1_id,
	batch.kerani_harvest_id,
	est.operating_unit_id,
	rkh.estate_id,
	com.id company_id
FROM
	sakti_foreman batch
	LEFT JOIN sakti_rkh rkh ON rkh.id = batch.rkh_id
	LEFT JOIN block_agg bagg ON bagg.foreman_id = batch.id AND bagg.harvest_date = rkh.rkh_date
	LEFT JOIN plantation_estate est ON est.id = rkh.estate_id
	LEFT JOIN res_company com ON com.id = rkh.company_id
	JOIN holiday h ON TRUE
	JOIN params p ON TRUE
WHERE
	rkh.rkh_date = p.current_date 
;

-- Hasil Panen - Lines
WITH params AS (
	SELECT
		'41d68b8e-4d3c-4f4b-8232-9b9997febd8c'::UUID bkm_id
)
SELECT 
	hvt.emp_id,
	hvt.attendance_type_id,
	loc.block_id,
	hv.tph_id,
	bkm.ha_amt,
	hv.bunch_qty,
	hv.loose_fruit_qty 
FROM
	sakti_harvest hv
	LEFT JOIN sakti_harvester hvt ON hvt.id = hv.harvester_id 
	LEFT JOIN sakti_location loc ON loc.id = hv.location_id 
	LEFT JOIN sakti_bkm bkm ON bkm.harvester_id = hv.harvester_id AND bkm.location_id = hv.location_id
	JOIN params p ON TRUE
WHERE
	hvt.foreman_id = p.bkm_id
;

-- numpang nyatet
WITH params AS (
	SELECT
		'20260304' AS current_date
),
bjr AS (
	SELECT
		bjr_avg.planted_block_id block_id,
		bjr_avg.tahun_kalkulasi avg_year,
		bjr_avg.periode_kalkulasi::INTEGER avg_month,
		bjr_avg.avg_weight
	FROM
		plantation_average_ffb bjr_avg
),
weight_ref_sum AS (
	SELECT
		rkh.rkh_date date,
		rkh.division_id,
		SUM(hv.bunch_qty) AS bunch_qty,
		SUM(hv.bunch_qty * COALESCE(bjr.avg_weight,0)) AS weight_ref_sum
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvt ON hvt.id = hv.harvester_id
		LEFT JOIN sakti_foreman batch ON batch.id = hvt.foreman_id
		LEFT JOIN sakti_rkh rkh ON rkh.id = batch.rkh_id
		LEFT JOIN plantation_harvest_staging tph ON tph.id = hv.tph_id
		LEFT JOIN params p ON TRUE
		LEFT JOIN bjr 
			ON bjr.block_id = tph.planted_block_id
			AND bjr.avg_year = DATE_PART('year', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
			AND bjr.avg_month = DATE_PART('month', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
	WHERE
		TO_CHAR(rkh.rkh_date, 'YYYYMMDD') = p.current_date
	GROUP BY
		rkh.rkh_date,
		rkh.division_id
),
weight_by_hvt AS (
	SELECT
		hvt.emp_id,
		rkh.rkh_date date,
		SUM(hv.bunch_qty) AS bunch_qty,
		SUM(hv.bunch_qty * COALESCE(bjr.avg_weight,0)) AS weight_by_hvt
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvt ON hvt.id = hv.harvester_id
		LEFT JOIN sakti_foreman batch ON batch.id = hvt.foreman_id
		LEFT JOIN sakti_rkh rkh ON rkh.id = batch.rkh_id
		LEFT JOIN plantation_harvest_staging tph ON tph.id = hv.tph_id
		LEFT JOIN params p ON TRUE
		LEFT JOIN bjr 
			ON bjr.block_id = tph.planted_block_id
			AND bjr.avg_year = DATE_PART('year', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
			AND bjr.avg_month = DATE_PART('month', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
	WHERE
		TO_CHAR(rkh.rkh_date, 'YYYYMMDD') = p.current_date
	GROUP BY
		hvt.emp_id,
		rkh.rkh_date
),
weighbridge AS (
	SELECT DISTINCT
		wb.date_posting,
		spb.division_id,
		-- sbp.id,
		SUM(wb.net_weight) wb_weight
	FROM
		weighbridge_ticket wb
		LEFT JOIN weighbridge_ticket_raw raw ON raw.weighbridge_ticket_id = wb.id
		LEFT JOIN (SELECT DISTINCT spb_id, divisi_id division_id FROM mill_spb) spb ON spb.spb_id = wb.id
		-- LEFT JOIN sakti_spb spb ON spb.id = wb.spb_id
		LEFT JOIN params p ON TRUE
	WHERE
		wb.transaction_type_id IN (86)
		AND wb.state = 'valid'
		AND raw.status_delete = '0'
		AND TO_CHAR(wb.date_posting, 'YYYYMMDD') = p.current_date
	GROUP BY
		wb.date_posting,
		wb.plantation_division_id,
		spb.division_id
),
premi_rate AS (
	SELECT
		rt.avg_ffb_range_from bjr_min,
		rt.avg_ffb_range_to bjr_max,
		rt.base_weight,
		rt.rate_1,
		rt.rate_3 
	FROM
		plantation_harvest_premi_rate rt
		LEFT JOIN plantation_harvest_premi_rule rl ON rl.id = rt.rule_id 
	WHERE
		rl.company_id = 1
		AND rl.active 
),
avg_weightbase_by_emp AS (
	SELECT
		hv.harvester_id,
		SUM(pr.base_weight * (((hv.bunch_qty * COALESCE(bjr.avg_weight,0)) / wrs.weight_ref_sum) * wb.wb_weight / wbh.weight_by_hvt)) AS total_avg_base_weight
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvt ON hvt.id = hv.harvester_id
		LEFT JOIN sakti_foreman batch ON batch.id = hvt.foreman_id
		LEFT JOIN sakti_rkh rkh ON rkh.id = batch.rkh_id
		LEFT JOIN plantation_harvest_staging tph ON tph.id = hv.tph_id
		JOIN params p ON TRUE
		LEFT JOIN bjr bjr ON bjr.block_id = tph.planted_block_id
			AND bjr.avg_year = DATE_PART('year', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
			AND bjr.avg_month = DATE_PART('month', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
		LEFT JOIN weight_ref_sum wrs ON wrs.division_id = rkh.division_id
		LEFT JOIN weight_by_hvt wbh ON wbh.emp_id = hvt.emp_id
		LEFT JOIN weighbridge wb ON wb.division_id = rkh.division_id
		LEFT JOIN premi_rate pr ON (
			((hv.bunch_qty * COALESCE(bjr.avg_weight,0)) / wrs.weight_ref_sum) * wb.wb_weight / hv.bunch_qty) BETWEEN pr.bjr_min AND pr.bjr_max
	WHERE
		TO_CHAR(rkh.rkh_date, 'YYYYMMDD') = p.current_date
	GROUP BY
		hv.harvester_id,
		rkh.rkh_date
),
base_by_emp AS (
	SELECT
		hv.harvester_id,
		SUM(
			((hv.bunch_qty * COALESCE(bjr.avg_weight,0)) / wrs.weight_ref_sum) * wb.wb_weight
			-
			(((hv.bunch_qty * COALESCE(bjr.avg_weight,0)) / wrs.weight_ref_sum) * wb.wb_weight
				/ wbh.weight_by_hvt * CASE WHEN wbh.weight_by_hvt - awbe.total_avg_base_weight > 0 THEN wbh.weight_by_hvt - awbe.total_avg_base_weight ELSE 0 END)
		) AS total_base
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvt ON hvt.id = hv.harvester_id
		LEFT JOIN sakti_foreman batch ON batch.id = hvt.foreman_id
		LEFT JOIN sakti_rkh rkh ON rkh.id = batch.rkh_id
		LEFT JOIN plantation_harvest_staging tph ON tph.id = hv.tph_id
		JOIN params p ON TRUE
		LEFT JOIN bjr bjr ON bjr.block_id = tph.planted_block_id
			AND bjr.avg_year = DATE_PART('year', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
			AND bjr.avg_month = DATE_PART('month', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
		LEFT JOIN weight_ref_sum wrs ON wrs.division_id = rkh.division_id
		LEFT JOIN weight_by_hvt wbh ON wbh.emp_id = hvt.emp_id
		LEFT JOIN weighbridge wb ON wb.division_id = rkh.division_id
		LEFT JOIN avg_weightbase_by_emp awbe ON awbe.harvester_id = hv.harvester_id
	WHERE
		TO_CHAR(rkh.rkh_date, 'YYYYMMDD') = p.current_date
	GROUP BY
		hv.harvester_id
),
q1 AS (
	SELECT
		rkh.division_id,
		batch.id batch_id,
		hvt.emp_id emp_id,
		CONCAT('[',emp.nomor_induk_pegawai,']', ' ', emp.name) emp_name,
		rkh.rkh_date date,
		rkh.rkh_nbr,
		hv.harvest_nbr,
		block.name block,
		hv.tph_id,
		tph.name tph,
		COALESCE(bkml.ha_amt, 0) ha_amt,
		hv.bunch_qty,
		COALESCE(bjr.avg_weight, 0) bjr,
		hv.bunch_qty * COALESCE(bjr.avg_weight, 0) weight_ref,
		wrs.weight_ref_sum,
		wb.wb_weight,
		(((hv.bunch_qty * COALESCE(bjr.avg_weight, 0)) / wrs.weight_ref_sum) * wb.wb_weight) real_weight,
		(((hv.bunch_qty * COALESCE(bjr.avg_weight, 0)) / wrs.weight_ref_sum) * wb.wb_weight) / hv.bunch_qty real_bjr,
		wbh.weight_by_hvt,
		pr.base_weight,
		(((hv.bunch_qty * COALESCE(bjr.avg_weight, 0)) / wrs.weight_ref_sum) * wb.wb_weight) / wbh.weight_by_hvt ratio,
		pr.base_weight * ((((hv.bunch_qty * COALESCE(bjr.avg_weight, 0)) / wrs.weight_ref_sum) * wb.wb_weight) / wbh.weight_by_hvt) avg_base_weight,
		awbe.total_avg_base_weight,
		CASE WHEN wbh.weight_by_hvt - awbe.total_avg_base_weight > 0 THEN wbh.weight_by_hvt - awbe.total_avg_base_weight ELSE 0 END overbase_by_emp,
		(((hv.bunch_qty * COALESCE(bjr.avg_weight, 0)) / wrs.weight_ref_sum) * wb.wb_weight) / wbh.weight_by_hvt
			* CASE WHEN wbh.weight_by_hvt - awbe.total_avg_base_weight > 0 THEN wbh.weight_by_hvt - awbe.total_avg_base_weight ELSE 0 END overbase,
		(((hv.bunch_qty * COALESCE(bjr.avg_weight, 0)) / wrs.weight_ref_sum) * wb.wb_weight)
			- ((((hv.bunch_qty * COALESCE(bjr.avg_weight, 0)) / wrs.weight_ref_sum) * wb.wb_weight) / wbh.weight_by_hvt
			* CASE WHEN wbh.weight_by_hvt - awbe.total_avg_base_weight > 0 THEN wbh.weight_by_hvt - awbe.total_avg_base_weight ELSE 0 END) base,
		abe.total_base 
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvt ON hvt.id = hv.harvester_id  
		LEFT JOIN sakti_foreman batch ON batch.id = hvt.foreman_id
		LEFT JOIN sakti_rkh rkh ON rkh.id = batch.rkh_id 
		LEFT JOIN sakti_bkm bkml ON bkml.harvester_id = hv.harvester_id AND bkml.location_id = hv.location_id 
		LEFT JOIN hr_employee emp ON emp.id = hvt.emp_id
		LEFT JOIN plantation_harvest_staging tph on tph.id = hv.tph_id 
		LEFT JOIN plantation_land_planted block ON block.id = tph.planted_block_id
		LEFT JOIN params p ON TRUE
		LEFT JOIN bjr bjr ON bjr.block_id = tph.planted_block_id
			AND bjr.avg_year = DATE_PART('year', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
			AND bjr.avg_month = DATE_PART('month', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
		LEFT JOIN weight_ref_sum wrs ON wrs.division_id = rkh.division_id
		LEFT JOIN weight_by_hvt wbh ON wbh.emp_id = hvt.emp_id
		LEFT JOIN weighbridge wb ON TO_CHAR(wb.date_posting, 'YYYYMMDD') = p.current_date AND wb.division_id = rkh.division_id
		LEFT JOIN sakti_taksasi tak ON TO_CHAR(tak.harvest_date, 'YYYYMMDD') = p.current_date AND tak.block_id = tph.planted_block_id
		LEFT JOIN premi_rate pr ON ((((hv.bunch_qty * COALESCE(bjr.avg_weight, 0)) / wrs.weight_ref_sum) * wb.wb_weight) / hv.bunch_qty) BETWEEN pr.bjr_min AND pr.bjr_max 
		LEFT JOIN avg_weightbase_by_emp awbe ON awbe.harvester_id = hv.harvester_id
		LEFT JOIN base_by_emp abe ON abe.harvester_id = hv.harvester_id
	WHERE
		TO_CHAR(rkh.rkh_date, 'YYYYMMDD') = p.current_date
)
SELECT
	q1.division_id,
	q1.batch_id,
	q1.emp_id,
	q1.emp_name,
	q1.date,
	q1.rkh_nbr,
	q1.harvest_nbr,
	q1.block,
	q1.tph_id,
	q1.tph,
	q1.ha_amt,
	q1.bunch_qty,
	q1.bjr,
	q1.weight_ref,
	q1.weight_ref_sum,
	q1.wb_weight,
	q1.real_bjr,
	q1.weight_by_hvt,
	q1.base_weight,
	q1.avg_base_weight,
	q1.total_avg_base_weight,
	q1.overbase_by_emp,
	q1.overbase,
	q1.base,
	q1.total_base 
FROM 
	q1
ORDER BY
	q1.date,
	q1.emp_name,
	q1.block,
	q1.tph
;







SELECT
	hv.harvester_id,
	SUM(
		((hv.bunch_qty * COALESCE(bjr.avg_weight,0)) / wrs.weight_ref_sum) 
		* wb.wb_weight
	) AS total_real_weight,
	wbh.weight_by_hvt,
	SUM(
		((hv.bunch_qty * COALESCE(bjr.avg_weight,0)) / wrs.weight_ref_sum) 
		* wb.wb_weight
	) / wbh.weight_by_hvt AS ratio,
	pr.base_weight,
	pr.base_weight *
	(
		SUM(
			((hv.bunch_qty * COALESCE(bjr.avg_weight,0)) / wrs.weight_ref_sum) 
			* wb.wb_weight
		) / wbh.weight_by_hvt
	) AS avg_base_weight
FROM
	sakti_harvest hv
	LEFT JOIN sakti_harvester hvt ON hvt.id = hv.harvester_id
	LEFT JOIN sakti_foreman batch ON batch.id = hvt.foreman_id
	LEFT JOIN sakti_rkh rkh ON rkh.id = batch.rkh_id
	LEFT JOIN params p ON TRUE
	LEFT JOIN bjr
		ON bjr.block_id = tph.planted_block_id
		AND bjr.avg_year = DATE_PART('year', p.current_date - INTERVAL '1 month')
		AND bjr.avg_month = DATE_PART('month', p.current_date - INTERVAL '1 month')
	LEFT JOIN weight_ref_sum wrs ON wrs.division_id = rkh.division_id
	LEFT JOIN weight_by_hvt wbh ON wbh.harvester_id = hv.harvester_id
	LEFT JOIN weighbridge wb ON wb.division_id = rkh.division_id
	LEFT JOIN premi_rate pr 
		ON (
			((hv.bunch_qty * COALESCE(bjr.avg_weight,0)) / wrs.weight_ref_sum) 
			* wb.wb_weight
		) / hv.bunch_qty 
		BETWEEN pr.bjr_min AND pr.bjr_max
WHERE
	rkh.rkh_date = p.current_date
GROUP BY
	hv.harvester_id,
	hvt.emp_id,
	emp.nomor_induk_pegawai,
	emp.name,
	wbh.weight_by_hvt,
	pr.base_weight


