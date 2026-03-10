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
block_ids AS (
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
	bkm.id bkm_id,
	rkh.rkh_date date,
	h.is_holiday,
	bids.planted_block_ids,
	--f.is_kutip_required,
	bkm.foreman_group_id,
	bkm.foreman_id,
	bkm.foreman1_id,
	bkm.kerani_harvest_id,
	est.operating_unit_id,
	rkh.estate_id,
	com.id company_id
FROM
	sakti_foreman bkm
	LEFT JOIN sakti_rkh rkh ON rkh.id = bkm.rkh_id
	LEFT JOIN block_ids bids ON bids.foreman_id = bkm.id AND bids.harvest_date = rkh.rkh_date
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
	hvr.emp_id,
	hvr.attendance_type_id,
	loc.block_id,
	hv.tph_id,
	bkm.ha_amt,
	hv.bunch_qty,
	hv.loose_fruit_qty 
FROM
	sakti_harvest hv
	LEFT JOIN sakti_harvester hvr ON hvr.id = hv.harvester_id 
	LEFT JOIN sakti_location loc ON loc.id = hv.location_id 
	LEFT JOIN sakti_bkm bkm ON bkm.harvester_id = hv.harvester_id AND bkm.location_id = hv.location_id
	JOIN params p ON TRUE
WHERE
	hvr.foreman_id = p.bkm_id
;


