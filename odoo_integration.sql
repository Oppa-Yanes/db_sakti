-- penyesuaian tabel di odoo
ALTER TABLE plantation_batch_harvest ADD COLUMN sakti_batch_id UUID;
ALTER TABLE plantation_harvest 
	ADD COLUMN sakti_batch_line_id UUID,
	ADD COLUMN ref_bjr NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN ref_weight NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN ref_weight_emp NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN ref_weight_total NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN wb_weight NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN real_weight_emp NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN ratio NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN avg_weightbase_emp NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN overbase_emp NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN base NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN base_emp NUMERIC(18,6) DEFAULT 0,
	ADD COLUMN hk_emp NUMERIC(18,6) DEFAULT 0
	;
ALTER TABLE plantation_harvest_penalty ADD COLUMN staging_location_id INT4,
	ADD CONSTRAINT fk_plantation_harvest_staging FOREIGN KEY (staging_location_id) REFERENCES plantation_harvest_staging(id);

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

-- Hasil Panen - Lines dan Premi
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

-- Tabel untuk menyimpan data JEJAK mutu buah ke Odoo
-- Nama Tabel: jejak_mutu_buah
DROP TABLE IF EXISTS jejak_mutu_buah CASCADE;
CREATE TABLE jejak_mutu_buah (
	id SERIAL4 PRIMARY KEY,
	jejak_id INT4,
	jejak_date DATE,
	estate_id INT4,
	estate VARCHAR,
	division_id INT4,
	division VARCHAR,
	inspector_id INT4,
	inspector_nip VARCHAR,
	inspector_name VARCHAR,
	inspector_job_level VARCHAR,
	inspector_job_name VARCHAR,
	harvester_id INT4,
	harvester_nip VARCHAR,
	harvester_name VARCHAR,
	block_id INT4,
	block VARCHAR,
	tph_id INT4,
	tph VARCHAR,
	total_qty FLOAT8 DEFAULT 0,
	ripe_qty FLOAT8 DEFAULT 0,
	unripe_qty FLOAT8 DEFAULT 0,
	rotten_qty FLOAT8 DEFAULT 0,
	lstalk_qty FLOAT8 DEFAULT 0,
	loose_qty FLOAT8 DEFAULT 0,
	abnormal_01_qty FLOAT8 DEFAULT 0,
	abnormal_02_qty FLOAT8 DEFAULT 0,
	abnormal_03_qty FLOAT8 DEFAULT 0,
	abnormal_04_qty FLOAT8 DEFAULT 0,
	create_uid INT4 NULL,
	create_date TIMESTAMP NULL,
	write_uid INT4 NULL,
	write_date TIMESTAMP NULL
);

-- Nama Tabel: jejak_mutu_ancak
DROP TABLE IF EXISTS jejak_mutu_ancak CASCADE;
CREATE TABLE jejak_mutu_ancak (
	id SERIAL4 PRIMARY KEY,
	jejak_id INT4,
	jejak_date DATE,
	estate_id INT4,
	estate VARCHAR,
	division_id INT4,
	division VARCHAR,
	inspector_id INT4,
	inspector_nip VARCHAR,
	inspector_name VARCHAR,
	inspector_job_level VARCHAR,
	inspector_job_name VARCHAR,
	harvester_id INT4,
	harvester_nip VARCHAR,
	harvester_name VARCHAR,
	block_id INT4,
	block VARCHAR,
	line_nbr INT4,
	P00 FLOAT8 DEFAULT 0,
	P01 FLOAT8 DEFAULT 0,
	P02 FLOAT8 DEFAULT 0,
	P03 FLOAT8 DEFAULT 0,
	P04 FLOAT8 DEFAULT 0,
	P05 FLOAT8 DEFAULT 0,
	P06 FLOAT8 DEFAULT 0,
	P07 FLOAT8 DEFAULT 0,
	create_uid INT4 NULL,
	create_date TIMESTAMP NULL,
	write_uid INT4 NULL,
	write_date TIMESTAMP NULL
);

-- Query untuk mentransfer data Jejak ke Odoo 
WITH params AS (
	SELECT
		11 category_id,
		'20260309' inspection_date
)
INSERT INTO jejak_mutu_buah (
	jejak_id,
	jejak_date,
	estate_id,
	estate,
	division_id,
	division,
	inspector_id,
	inspector_nip,
	inspector_name,
	inspector_job_level,
	inspector_job_name,
	harvester_id,
	harvester_nip,
	harvester_name,
	block_id,
	block,
	tph_id,
	tph,
	total_qty,
	ripe_qty,
	unripe_qty,
	rotten_qty,
	lstalk_qty,
	loose_qty,
	abnormal_01_qty,
	abnormal_02_qty,
	abnormal_03_qty,
	abnormal_04_qty,
	create_uid,
	write_date
)
SELECT
	bi.id jejak_id,
	i.date jejak_date,
	est.odoo_id estate_id,
	est.name estate,
	div.odoo_id division_id,
	div.name division,
	spv.id inspector_id,
	spv.nip inspector_nip,
	spv.emp_name inspector_name,
	spv.job_level inspector_job_level,
	spv.job_name inspector_job_name,
	hvt.id harvester_id,
	hvt.nip harvester_nip,
	hvt.emp_name harvester_name,
	block.odoo_id block_id,
	block.code block,
	tph.id tph_id,
	tph.code tph,
	bi.ripe_qty + bi.unripe_qty + bi.rotten_qty + bi.lstalk_qty total_qty,
	bi.ripe_qty,
	bi.unripe_qty,
	bi.rotten_qty,
	bi.lstalk_qty,
	bi.loose_qty,
	bi.abnormal_01_qty,
	bi.abnormal_02_qty,
	bi.abnormal_03_qty,
	bi.abnormal_04_qty,
	CURRENT_TIMESTAMP create_date,
	CURRENT_TIMESTAMP write_date
FROM 
	blok_inspeksi bi
	LEFT JOIN inspeksi i ON i.id = bi.inspeksi_id
	LEFT JOIN users u ON u.uuid = i.user_uuid
	LEFT JOIN employee spv ON spv.id = u.odoo_id
	LEFT JOIN employee hvt ON hvt.id = bi.emp_pemanen_id 
	LEFT JOIN foreman_group fg ON fg.id = hvt.foreman_group_id 
	LEFT JOIN blok block ON block.id = bi.blok_id 
	LEFT JOIN tph tph ON tph.id = bi.tph_id 
	LEFT JOIN estate est ON est.id = bi.estate_id 
	LEFT JOIN divisi div ON div.id = bi.divisi_id
	LEFT JOIN penalty pe ON pe.id = bi.penalty_id 
	JOIN params p ON TRUE 
WHERE
	LEFT(spv.job_level,1) IN ('A','B','C','D')
	AND bi.category_id = p.category_id 
	AND TO_CHAR(i.date,'YYYYMMDD') = p.inspection_date
ON CONFLICT (jejak_id) DO UPDATE SET
	jejak_date			= EXCLUDED.jejak_date,
	estate_id           = EXCLUDED.estate_id,
	estate              = EXCLUDED.estate,
	division_id			= EXCLUDED.division_id,
	division			= EXCLUDED.division,
	inspector_id		= EXCLUDED.spv_id,
	inspector_nip		= EXCLUDED.spv_nip,
	inspector_name		= EXCLUDED.spv_name,
	inspector_job_level	= EXCLUDED.spv_job_level,
	inspector_job_name	= EXCLUDED.spv_job_name,
	harvester_nip       = EXCLUDED.harvester_nip,
	harvester_name      = EXCLUDED.harvester_name,
	block_id            = EXCLUDED.block_id,
	block               = EXCLUDED.block,
	total_qty           = EXCLUDED.total_qty,
	ripe_qty            = EXCLUDED.ripe_qty,
	unripe_qty          = EXCLUDED.unripe_qty,
	rotten_qty          = EXCLUDED.rotten_qty,
	lstalk_qty          = EXCLUDED.lstalk_qty,
	loose_qty           = EXCLUDED.loose_qty,
	abnormal_01_qty     = EXCLUDED.abnormal_01_qty,
	abnormal_02_qty     = EXCLUDED.abnormal_02_qty,
	abnormal_03_qty     = EXCLUDED.abnormal_03_qty,
	abnormal_04_qty     = EXCLUDED.abnormal_04_qty,
	write_date          = CURRENT_TIMESTAMP
;

-- Query untuk mentransfer data Jejak ke Odoo 
WITH params AS (
	SELECT
		10 category_id,
		'20260309' inspection_date
)
INSERT INTO jejak_mutu_buah (
	jejak_id,
	jejak_date,
	estate_id,
	estate,
	division_id,
	division,
	inspector_id,
	inspector_nip,
	inspector_name,
	inspector_job_level,
	inspector_job_name,
	harvester_id,
	harvester_nip,
	harvester_name,
	block_id,
	block,
	line_nbr,
	p00,
	p01,
	p02,
	p03,
	p04,
	p05,
	p06,
	p07,
	create_uid,
	write_date
)
SELECT
	bi.id jejak_id,
	i.date jejak_date,
	est.odoo_id estate_id,
	est.name estate,
	div.odoo_id division_id,
	div.name division,
	spv.id inspector_id,
	spv.nip inspector_nip,
	spv.emp_name inspector_name,
	spv.job_level inspector_job_level,
	spv.job_name inspector_job_name,
	hvt.id harvester_id,
	hvt.nip harvester_nip,
	hvt.emp_name harvester_name,
	block.odoo_id block_id,
	block.code block,
	bi.no_baris line_nbr,
	COALESCE(SUM(CASE WHEN pe.code = 'P00' THEN 1 END), 0) AS p00,
	COALESCE(SUM(CASE WHEN pe.code = 'P01' THEN bi.qty END), 0) AS p01,
	COALESCE(SUM(CASE WHEN pe.code = 'P02' THEN bi.qty END), 0) AS p02,
	COALESCE(SUM(CASE WHEN pe.code = 'P03' THEN bi.qty END), 0) AS p03,
	COALESCE(SUM(CASE WHEN pe.code = 'P04' THEN bi.qty END), 0) AS p04,	
	COALESCE(SUM(CASE WHEN pe.code = 'P05' THEN bi.qty END), 0) AS p05,	
	COALESCE(SUM(CASE WHEN pe.code = 'P06' THEN bi.qty END), 0) AS p06,	
	COALESCE(SUM(CASE WHEN pe.code = 'P07' THEN bi.qty END), 0) AS p07,
	CURRENT_TIMESTAMP create_date,
	CURRENT_TIMESTAMP write_date
FROM 
	blok_inspeksi bi
	LEFT JOIN inspeksi i ON i.id = bi.inspeksi_id
	LEFT JOIN users u ON u.uuid = i.user_uuid
	LEFT JOIN employee harvester ON harvester.id = bi.emp_pemanen_id 
	LEFT JOIN blok block ON block.id = bi.blok_id 
	LEFT JOIN estate est ON est.id = bi.estate_id 
	LEFT JOIN divisi div ON div.id = bi.divisi_id 
	LEFT JOIN penalty pe ON pe.id = bi.penalty_id 
	LEFT JOIN employee spv ON spv.id = u.odoo_id
	LEFT JOIN employee hvt ON hvt.id = bi.emp_pemanen_id 
	JOIN params p ON TRUE 
WHERE
	bi.category_id = p.category_id 
	AND TO_CHAR(i.date,'YYYYMMDD') = p.inspection_date	
GROUP BY
	bi.id,
	i.date,
	est.odoo_id,
	est.name,
	div.odoo_id,
	div.name,
	spv.id,
	spv.nip,
	spv.emp_name,
	spv.job_level,
	spv.job_name,
	hvt.id,
	hvt.nip,
	hvt.emp_name,
	block.odoo_id,
	block.code,
	bi.no_baris
ON CONFLICT (jejak_id) DO UPDATE SET
	jejak_date			= EXCLUDED.jejak_date,
	estate_id           = EXCLUDED.estate_id,
	estate              = EXCLUDED.estate,
	division_id			= EXCLUDED.division_id,
	division			= EXCLUDED.division,
	inspector_id		= EXCLUDED.spv_id,
	inspector_nip		= EXCLUDED.spv_nip,
	inspector_name		= EXCLUDED.spv_name,
	inspector_job_level	= EXCLUDED.spv_job_level,
	inspector_job_name	= EXCLUDED.spv_job_name,
	harvester_nip       = EXCLUDED.harvester_nip,
	harvester_name      = EXCLUDED.harvester_name,
	block_id            = EXCLUDED.block_id,
	block               = EXCLUDED.block,
	line_nbr			= EXCLUDED.line_nbr,
	p00					= EXCLUDED.p00,
	p01					= EXCLUDED.p01,
	p02					= EXCLUDED.p02,
	p03					= EXCLUDED.p03,
	p04					= EXCLUDED.p04,
	p05					= EXCLUDED.p05,
	p06					= EXCLUDED.p06,
	p07					= EXCLUDED.p07,
	write_date			= CURRENT_TIMESTAMP
;

-- Query pembentuk Harvest Pinalty (mutu buah)
WITH params AS (
	SELECT
		1 AS company_id,
		DATE '2026-03-09' AS current_date,
		1 batch_id -- ID dari Batch Harvest
),
pharvest AS (
	SELECT DISTINCT
		hv.id harvest_id,
		hv.planted_block_id,
		hv.employee_id,
		hv.staging_location_id
	FROM
		plantation_harvest hv
		JOIN params p ON TRUE
	WHERE 
		hv.harvest_batch_id = p.batch_id 
)
SELECT
	est.operating_unit_id,
	est.company_id,
	hv.harvest_id,
	rs.block_id planted_block_id,
	rs.tph_id staging_location_id,
	rs.harvester_id employee_id,
	prule.id penalty_rule_id,
	prate.id penalty_id,
	prate.name name,
	x.penalty_code code,
	uom.name unit,
	prate.uom_id uom_id,
	x.penalty_amt penalty_qty,
	COALESCE(prate.rate, 0) price_unit,
	COALESCE(x.penalty_amt * prate.rate, 0) penalty_amount
FROM
	jejak_mutu_buah rs
	LEFT JOIN pharvest hv ON hv.planted_block_id = rs.block_id 
		AND hv.staging_location_id = rs.tph_id AND hv.employee_id = rs.harvester_id
	CROSS JOIN LATERAL (VALUES
			('MTH', rs.unripe_qty),
			('BST', rs.rotten_qty),
			('BTP', rs.lstalk_qty)
		) AS x (penalty_code, penalty_amt)
	LEFT JOIN plantation_harvest_penalty_rate prate ON prate.code = x.penalty_code
	LEFT JOIN plantation_harvest_penalty_rule prule ON prule.id = prate.rule_id
	LEFT JOIN uom_uom uom ON uom.id = prate.uom_id 
	LEFT JOIN plantation_estate est ON est.id = rs.estate_id
	JOIN params p ON TRUE
WHERE
	rs.jejak_date = p.current_date 
	AND x.penalty_amt > 1
	AND prule.active
	AND prule.company_id = p.company_id 
;
