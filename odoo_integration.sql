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

-- Hasil Panen - Premi
-- Perhitungan Lebih Basis yang belum diintegrasikan antara WB dengan SAKTI
WITH params AS (
	SELECT
		'20260304' AS current_date
),
holiday AS (
	SELECT 
		(EXTRACT(DOW FROM TO_DATE(p.current_date, 'YYYYMMDD')) = 0
			OR EXISTS (
				SELECT 1 
				FROM gbs_hr_holiday_line hl 
				WHERE hl.date = TO_DATE(p.current_date, 'YYYYMMDD'))
		) AS is_holiday
	FROM
		params p
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
		rt.base_weight weightbase,
		rt.rate_1,
		rt.rate_3,
		rl.premi_ffb_loose_rate,
		rl.premi_ffb_loose_rate_2,
		rl.premi_double_base_achieved_rate,
		rl.additional_base_for_panen_without_loose 
	FROM
		plantation_harvest_premi_rate rt
		LEFT JOIN plantation_harvest_premi_rule rl ON rl.id = rt.rule_id 
	WHERE
		rl.company_id = 1
		AND rl.active 
),
q1 AS (
	SELECT
		rkh.division_id,
		batch.id batch_id,
		hvt.is_kutip_required,
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
		COALESCE(bjr.avg_weight, 0) ref_bjr,
		hv.bunch_qty * COALESCE(bjr.avg_weight, 0) ref_weight,
		wb.wb_weight,
		hv.loose_fruit_qty
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
		LEFT JOIN weighbridge wb ON TO_CHAR(wb.date_posting, 'YYYYMMDD') = p.current_date AND wb.division_id = rkh.division_id
		LEFT JOIN bjr bjr ON bjr.block_id = tph.planted_block_id
			AND bjr.avg_year = DATE_PART('year', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
			AND bjr.avg_month = DATE_PART('month', TO_DATE(p.current_date, 'YYYYMMDD') - '1 mon'::INTERVAL)::INTEGER
	WHERE
		TO_CHAR(rkh.rkh_date, 'YYYYMMDD') = p.current_date
),
q2 AS (
	SELECT
		q1.*,
		rwe.ref_weight_emp,
		rwt.ref_weight_total,
		(((q1.bunch_qty * q1.ref_bjr) / rwt.ref_weight_total) * q1.wb_weight) real_weight
	FROM 
		q1
		LEFT JOIN (
			SELECT q1.emp_id, SUM(q1.bunch_qty * q1.ref_bjr) ref_weight_emp
			FROM q1
			GROUP BY q1.emp_id
		) rwe ON rwe.emp_id = q1.emp_id
		LEFT JOIN (
			SELECT SUM(q1.bunch_qty * q1.ref_bjr) ref_weight_total
			FROM q1
		) rwt ON TRUE
),
q3 AS (
	SELECT
		q2.*,
		q2.real_weight / q2.bunch_qty real_bjr,
		rwe.real_weight_emp,
		pr.weightbase + (
			CASE 
				WHEN NOT q2.is_kutip_required THEN pr.additional_base_for_panen_without_loose 
				ELSE 0
			END 
		) weightbase,
		(q2.real_weight / rwe.real_weight_emp) ratio,
		(q2.real_weight / rwe.real_weight_emp) * (
			pr.weightbase +
			CASE 
				WHEN NOT q2.is_kutip_required THEN pr.additional_base_for_panen_without_loose 
				ELSE 0 
			END
		) avg_weightbase
	FROM
		q2
		LEFT JOIN (
			SELECT q2.emp_id, SUM(q2.real_weight) real_weight_emp
			FROM q2
			GROUP BY q2.emp_id
		) rwe ON rwe.emp_id = q2.emp_id
		LEFT JOIN premi_rate pr ON (q2.real_weight / q2.bunch_qty) BETWEEN pr.bjr_min AND pr.bjr_max 
),
q4 AS (
	SELECT
		q3.*,
		awe.avg_weightbase_emp,
		GREATEST(q3.real_weight_emp - awe.avg_weightbase_emp, 0) AS overbase_emp,
		GREATEST(q3.real_weight_emp - awe.avg_weightbase_emp, 0) * q3.ratio overbase,
		q3.real_weight - (GREATEST(q3.real_weight_emp - awe.avg_weightbase_emp, 0) * q3.ratio) base
	FROM
		q3
		LEFT JOIN (
			SELECT q3.emp_id, SUM(q3.avg_weightbase) avg_weightbase_emp
			FROM q3
			GROUP BY q3.emp_id
		) awe ON awe.emp_id = q3.emp_id
),
q5 AS (
	SELECT
		q4.*,
		h.is_holiday,
		be.base_emp,
		(be.base_emp / q4.avg_weightbase_emp) * q4.ratio hk,
		(be.base_emp / q4.avg_weightbase_emp) hk_emp,
		CASE WHEN h.is_holiday THEN pr.rate_3 ELSE pr.rate_1 END premi_rate,
		((be.base_emp / q4.avg_weightbase_emp) * q4.ratio) * CASE WHEN h.is_holiday THEN pr.rate_3 ELSE pr.rate_1 END overbase_premi,
		CASE WHEN (q4.real_weight_emp / q4.avg_weightbase_emp) >= 2 THEN pr.premi_double_base_achieved_rate ELSE 0 END * q4.ratio doublebase_premi,
		pr.premi_ffb_loose_rate loose_fruit_rate,
		q4.loose_fruit_qty * pr.premi_ffb_loose_rate loose_fruit_premi
	FROM
		q4
		LEFT JOIN holiday h ON TRUE
		LEFT JOIN (
			SELECT q4.emp_id, SUM(q4.base) base_emp
			FROM q4
			GROUP BY q4.emp_id
		) be ON be.emp_id = q4.emp_id
		LEFT JOIN premi_rate pr ON q4.real_bjr BETWEEN pr.bjr_min AND pr.bjr_max
)
SELECT
	q5.division_id,
	q5.batch_id,
	q5.emp_id,
	q5.emp_name,
	q5.date,
	q5.is_holiday,
	q5.rkh_nbr,
	q5.harvest_nbr,
	q5.block,
	q5.tph_id,
	q5.tph,
	q5.ha_amt,
	q5.bunch_qty,
	q5.ref_bjr,
	q5.ref_weight,
	q5.ref_weight_emp,
	q5.ref_weight_total,
	q5.wb_weight,
	q5.real_weight,
	q5.real_bjr,
	q5.real_weight_emp,
	q5.weightbase,
	q5.ratio,
	q5.avg_weightbase,
	q5.avg_weightbase_emp,
	q5.overbase_emp,
	q5.overbase,
	q5.base,
	q5.base_emp,
	q5.hk,
	q5.hk_emp,
	q5.premi_rate,
	q5.overbase_premi,
	q5.doublebase_premi,
	q5.loose_fruit_qty,
	q5.loose_fruit_rate,
	q5.loose_fruit_premi,
	q5.overbase_premi + q5.doublebase_premi + q5.loose_fruit_premi total_premi
FROM 
	q5
ORDER BY
	q5.date,
	q5.emp_name,
	q5.block,
	q5.tph
;

