-- Hasil Panen - Header
WITH params AS (
	SELECT
		1 company_id,
		DATE '2026-03-09' current_date
),
holiday AS (
	SELECT 
		(EXTRACT(DOW FROM p.current_date) = 0
		 OR EXISTS (
			SELECT 1 
			FROM gbs_hr_holiday_line hl LEFT JOIN gbs_hr_holiday h ON h.id = hl.holiday_id
			WHERE
				h.company_id = p.company_id
				AND hl.date = p.current_date
			)
		) AS is_holiday
	FROM params p
),
block_agg AS (
	SELECT
		rkh.company_id,
		hvr.foreman_id,
		hv.harvest_date::DATE harvest_date,
		STRING_AGG(DISTINCT loc.block_id::TEXT, ', ') planted_block_ids
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_harvester hvr ON hvr.id = hv.harvester_id
		LEFT JOIN sakti_location loc ON loc.id = hv.location_id
		LEFT JOIN sakti_rkh rkh ON rkh.id = loc.rkh_id
	GROUP BY
		rkh.company_id,
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
	LEFT JOIN block_agg bagg ON bagg.foreman_id = batch.id AND bagg.harvest_date = rkh.rkh_date AND bagg.company_id = rkh.company_id
	LEFT JOIN plantation_estate est ON est.id = rkh.estate_id
	LEFT JOIN res_company com ON com.id = rkh.company_id
	JOIN holiday h ON TRUE
	JOIN params p ON TRUE
WHERE
	rkh.company_id = p.company_id
	AND rkh.rkh_date = p.current_date 
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
		1 AS company_id,
		DATE '2026-03-09' AS current_date,
		'41d68b8e-4d3c-4f4b-8232-9b9997febd8c'::UUID batch_id
),
holiday AS (
	SELECT 
		(EXTRACT(DOW FROM p.current_date) = 0
		 OR EXISTS (
			SELECT 1 
			FROM gbs_hr_holiday_line hl LEFT JOIN gbs_hr_holiday h ON h.id = hl.holiday_id
			WHERE
				h.company_id = p.company_id
				AND hl.date = p.current_date
			)
		) AS is_holiday
	FROM params p
),
bjr AS (
	SELECT
		planted_block_id AS block_id,
		tahun_kalkulasi AS avg_year,
		periode_kalkulasi::INT AS avg_month,
		avg_weight
	FROM plantation_average_ffb
),
weighbridge AS (
	SELECT
		COALESCE(SUM(wb.net_weight), 0) AS wb_weight
	FROM
		weighbridge_ticket wb
		JOIN params p ON TRUE
	WHERE
		wb.date_posting = p.current_date
		AND wb.company_id = p.company_id
		AND wb.spb_id IN (
			SELECT tr.id::TEXT FROM sakti_transport tr 
			WHERE tr.transport_date::DATE = p.current_date
		)
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
		JOIN params p ON TRUE
	WHERE
		rl.company_id = p.company_id
		AND rl.active
),
base_data AS (
	SELECT
		hv.id batch_line_id,
		hvt.id batch_line_premi_id,
		batch.id batch_id,
		est.operating_unit_id,
		rkh.company_id,
		rkh.estate_id,
		rkh.division_id,
		hvt.is_kutip_required,
		hvt.emp_id,
		emp.nomor_induk_pegawai emp_nip,
		emp.name emp_name,
		hvt.attendance_type_id,
		att.code attendance_type_code,
		batch.rkh_id,
		rkh.rkh_nbr,
		rkh.rkh_date AS date,
		hv.harvest_nbr,
		loc.block_id,
		block.name AS block,
		hv.tph_id,
		tph.name AS tph,
		COALESCE(bkml.ha_amt, 0) ha_amt,
		hv.bunch_qty,
		COALESCE(bjr.avg_weight, 0) ref_bjr,
		hv.bunch_qty * COALESCE(bjr.avg_weight, 0) ref_weight,
		wb.wb_weight,
		hv.loose_fruit_qty
	FROM
		sakti_harvest hv
		LEFT JOIN sakti_location loc ON loc.id = hv.location_id
		LEFT JOIN sakti_harvester hvt ON hvt.id = hv.harvester_id  
		LEFT JOIN sakti_foreman batch ON batch.id = hvt.foreman_id
		LEFT JOIN sakti_rkh rkh ON rkh.id = batch.rkh_id 
		LEFT JOIN sakti_bkm bkml ON bkml.harvester_id = hv.harvester_id 
			AND bkml.location_id = hv.location_id 
		LEFT JOIN hr_employee emp ON emp.id = hvt.emp_id
		LEFT JOIN plantation_land_planted block ON block.id = loc.block_id
		LEFT JOIN plantation_harvest_staging tph ON tph.id = hv.tph_id 
		LEFT JOIN plantation_estate est ON est.id = rkh.estate_id
		LEFT JOIN hr_attendance_type att ON att.id = hvt.attendance_type_id
		JOIN params p ON TRUE
		LEFT JOIN weighbridge wb ON TRUE
		LEFT JOIN bjr ON bjr.block_id = tph.planted_block_id
			AND bjr.avg_year = DATE_PART('year', p.current_date - INTERVAL '1 month')
			AND bjr.avg_month = DATE_PART('month', p.current_date - INTERVAL '1 month')
	WHERE
		rkh.company_id = p.company_id
		AND rkh.rkh_date = p.current_date
),
step1 AS (
	SELECT
		bd.*,
		SUM(bd.ref_weight) OVER () AS ref_weight_total,
		SUM(bd.ref_weight) OVER (PARTITION BY bd.emp_id) AS ref_weight_emp,
		(bd.ref_weight / SUM(bd.ref_weight) OVER ()) * bd.wb_weight AS real_weight
	FROM base_data bd
),
step2 AS (
	SELECT
		s1.*,
		SUM(s1.real_weight) OVER (PARTITION BY s1.emp_id) AS real_weight_emp,
		s1.real_weight / NULLIF(s1.bunch_qty, 0) AS real_bjr
	FROM step1 s1
),
step3 AS (
	SELECT
		s2.*,
		pr.weightbase +
			CASE 
				WHEN NOT s2.is_kutip_required 
					THEN pr.additional_base_for_panen_without_loose 
				ELSE 0
			END AS weightbase,
		COALESCE(s2.real_weight / NULLIF(s2.real_weight_emp, 0), 0) AS ratio,
		COALESCE(s2.real_weight / NULLIF(s2.real_weight_emp, 0), 0) *
			(pr.weightbase +
				CASE 
					WHEN NOT s2.is_kutip_required 
						THEN pr.additional_base_for_panen_without_loose 
					ELSE 0 
				END
			) AS avg_weightbase
	FROM
		step2 s2
		LEFT JOIN premi_rate pr ON s2.real_bjr BETWEEN pr.bjr_min AND pr.bjr_max
),
step4 AS (
	SELECT
		s3.*,
		SUM(s3.avg_weightbase) OVER (PARTITION BY s3.emp_id) AS avg_weightbase_emp
	FROM step3 s3
),
step5 AS (
	SELECT
		s4.*,
		GREATEST(s4.real_weight_emp - s4.avg_weightbase_emp, 0) AS overbase_emp,
		GREATEST(s4.real_weight_emp - s4.avg_weightbase_emp, 0) * s4.ratio AS overbase,
		s4.real_weight - (GREATEST(s4.real_weight_emp - s4.avg_weightbase_emp, 0) * s4.ratio) AS base
	FROM step4 s4
),
step6 AS (
	SELECT
		s5.*,
		SUM(s5.base) OVER (PARTITION BY s5.emp_id) AS base_emp
	FROM step5 s5
),
result_set AS (
	SELECT
		s6.*,
		h.is_holiday,
		COALESCE(s6.base_emp / NULLIF(s6.avg_weightbase_emp, 0), 0) * s6.ratio AS hk,
		COALESCE(s6.base_emp / NULLIF(s6.avg_weightbase_emp, 0), 0) AS hk_emp,
		CASE WHEN h.is_holiday THEN pr.rate_3 ELSE pr.rate_1 END AS premi_rate,
		s6.overbase * CASE WHEN h.is_holiday THEN pr.rate_3 ELSE pr.rate_1 END AS overbase_premi,
		pr.premi_double_base_achieved_rate doublebase_premi_rate,
		CASE 
			WHEN (s6.real_weight_emp / NULLIF(s6.avg_weightbase_emp, 0)) >= 2 
			THEN pr.premi_double_base_achieved_rate 
			ELSE 0 
		END * s6.ratio AS doublebase_premi,
		pr.premi_ffb_loose_rate AS loose_fruit_rate,
		s6.loose_fruit_qty * pr.premi_ffb_loose_rate AS loose_fruit_premi
	FROM step6 s6
	LEFT JOIN holiday h ON TRUE
	LEFT JOIN premi_rate pr ON s6.real_bjr BETWEEN pr.bjr_min AND pr.bjr_max
)
SELECT
	rs.batch_line_id,
	rs.batch_line_premi_id,
	rs.batch_id,
	rs.operating_unit_id,
	rs.company_id,
	rs.estate_id,
	rs.division_id,
	rs.emp_id,
	rs.emp_nip,
	rs.emp_name,
	rs.attendance_type_id,
	rs.attendance_type_code,
	rs.date,
	rs.is_holiday,
	rs.rkh_id,
	rs.rkh_nbr,
	rs.harvest_nbr,
	rs.block_id,
	rs.block,
	rs.tph_id,
	rs.tph,
	rs.ha_amt,
	rs.bunch_qty,
	rs.ref_bjr,
	rs.ref_weight,
	rs.ref_weight_emp,
	rs.ref_weight_total,
	rs.wb_weight,
	rs.real_weight,
	rs.real_bjr,
	rs.real_weight_emp,
	rs.weightbase,
	rs.ratio,
	rs.avg_weightbase,
	rs.avg_weightbase_emp,
	rs.overbase_emp,
	rs.overbase,
	rs.base,
	rs.base_emp,
	rs.hk,
	rs.hk_emp,
	rs.premi_rate,
	rs.overbase_premi,
	rs.doublebase_premi_rate,
	rs.doublebase_premi,
	rs.loose_fruit_qty,
	rs.loose_fruit_rate,
	rs.loose_fruit_premi,
	rs.overbase_premi + rs.doublebase_premi + rs.loose_fruit_premi AS total_premi
FROM
	result_set rs
	JOIN params p ON TRUE
WHERE
	rs.batch_id = p.batch_id
ORDER BY
	rs.date,
	rs.emp_nip,
	rs.emp_name,
	rs.block,
	rs.tph
;

