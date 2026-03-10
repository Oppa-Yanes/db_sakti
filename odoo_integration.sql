-- Hasil Panen Header
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
	f.id sakti_id,
	rkh.rkh_date date,
	h.is_holiday,
	bids.planted_block_ids,
	--f.is_kutip_required,
	f.foreman_group_id,
	f.foreman_id,
	f.foreman1_id,
	f.kerani_harvest_id,
	est.operating_unit_id,
	rkh.estate_id,
	com.id company_id
FROM
	sakti_foreman f
	LEFT JOIN sakti_rkh rkh ON rkh.id = f.rkh_id
	LEFT JOIN block_ids bids ON bids.foreman_id = f.id AND bids.harvest_date = rkh.rkh_date
	LEFT JOIN plantation_estate est ON est.id = rkh.estate_id
	LEFT JOIN res_company com ON com.id = rkh.company_id
	JOIN holiday h ON TRUE
	JOIN params p ON TRUE
WHERE
	rkh.rkh_date = p.current_date 
;
