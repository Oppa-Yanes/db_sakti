DROP TABLE IF EXISTS t_akp CASCADE;
CREATE TABLE t_akp (
    id UUID PRIMARY KEY,
    akp_nbr VARCHAR UNIQUE NOT NULL,
    akp_date TIMESTAMP NOT NULL,
	harvest_date DATE NOT NULL,
	stage char NOT NULL DEFAULT 'D',
	company_id SERIAL4 NOT NULL,
	estate_id SERIAL4 NOT NULL,
	division_id SERIAL4 NOT NULL,
    block_id SERIAL4 NOT NULL,
	company_odooid SERIAL4 NOT NULL,
	estate_odooid SERIAL4 NOT NULL,
	division_odooid SERIAL4 NOT NULL,
    block_odooid SERIAL4 NOT NULL,
    total_bunch_count INT4 NOT NULL DEFAULT 0,
    total_plant NUMERIC(8,2) NOT NULL DEFAULT 0,
    akp NUMERIC(8,2) NOT NULL DEFAULT 0,
	user_uuid UUID NOT NULL,
    date_sync TIMESTAMP,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP
);

DROP TABLE IF EXISTS t_akp_line CASCADE;
CREATE TABLE t_akp_line (
    id UUID PRIMARY KEY,
    akp_id UUID NOT NULL,
	baris_nbr INT4 NOT NULL DEFAULT 0,
	baris_nbr_1 INT4,
    total_plant NUMERIC(8,2) NOT NULL DEFAULT 0,
 	pic_path VARCHAR NOT NULL,
	pic_uri VARCHAR NOT NULL,
    date_sync TIMESTAMP,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,

    CONSTRAINT fk_akp FOREIGN KEY (akp_id) REFERENCES t_akp(id)
);

DROP TABLE IF EXISTS t_akp_point CASCADE;
CREATE TABLE t_akp_point (
    id UUID PRIMARY KEY,
    akp_line_id UUID NOT NULL,
	pokok_nbr INT4 NOT NULL DEFAULT 0,
	bunch_count INT4 NOT NULL DEFAULT 0,
	is_dead BOOLEAN NOT NULL DEFAULT FALSE,
	lat FLOAT NOT NULL DEFAULT 0,
    long FLOAT NOT NULL DEFAULT 0,
    date_sync TIMESTAMP,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,

    CONSTRAINT fk_akp_line FOREIGN KEY (akp_line_id) REFERENCES t_akp_line(id)
);


WITH akp_point AS (
	SELECT
		akp_point.akp_line_id,
		SUM(akp_point.bunch_count) bunch_count,
		SUM(CASE WHEN akp_point.is_dead THEN 1 ELSE 0 END) is_dead
	FROM
		t_akp_point akp_point
	GROUP BY
		akp_point.akp_line_id
),
premi_rate AS (
	SELECT 
		rule.operating_unit_id,
		rule.company_id,
		rate.range_from,
		rate.range_to,
		rate.base_weight,
		rate.rate1,
		rate.rate2,
		rate.rate3,
		rate.loose_rate1,
		rate.loose_rate2,
		rule.premi_loose_rate,
		rule.premi_loose_rate2,
		rule.premi_doublebase_rate,
		rule.additional_base_rate
	FROM
		m_premi_rate rate
		LEFT JOIN m_premi_rule rule ON rule.id = rate.rule_id 
	WHERE
		NOT rule.is_disabled
)
SELECT 
	akp.harvest_date,
	to_char(akp.harvest_date - interval '1 month', 'YYYYMM') xxx,
	akp.company_odooid,
	akp.estate_odooid,
	akp.division_odooid,
	akp.block_odooid,
	block.planted_area,
	block.plant_total,
	bjr.bjr,
	rate.base_weight,
	SUM(akp_point.bunch_count) / (SUM(akp_line.total_plant) - SUM(akp_point.is_dead)) akp,
	SUM(akp_point.bunch_count) / (SUM(akp_line.total_plant) - SUM(akp_point.is_dead)) * block.plant_total est_ripe_bunch,
	SUM(akp_point.bunch_count) / (SUM(akp_line.total_plant) - SUM(akp_point.is_dead)) * block.plant_total * bjr.bjr taksasi,
	(SUM(akp_point.bunch_count) / (SUM(akp_line.total_plant) - SUM(akp_point.is_dead)) * block.plant_total * bjr.bjr) / rate.base_weight hk,
	(SUM(akp_point.bunch_count) / (SUM(akp_line.total_plant) - SUM(akp_point.is_dead)) * block.plant_total * bjr.bjr) 
		/ ((SUM(akp_point.bunch_count) / (SUM(akp_line.total_plant) - SUM(akp_point.is_dead)) * block.plant_total * bjr.bjr) / rate.base_weight) output
FROM
	t_akp akp
	LEFT JOIN t_akp_line akp_line ON akp_line.akp_id = akp.id 
	LEFT JOIN m_block block ON block.id = akp.block_odooid 
	LEFT JOIN akp_point ON akp_point.akp_line_id = akp_line.id 
	LEFT JOIN m_bjr bjr ON bjr.period = to_char(akp.harvest_date - interval '2 month', 'YYYYMM') AND bjr.block_id = akp.block_odooid
	LEFT JOIN premi_rate rate ON bjr.bjr BETWEEN rate.range_from AND rate.range_to AND rate.company_id = akp.company_id 
WHERE 
	akp.harvest_date = '2025-10-01'
	AND akp.block_odooid = 674
GROUP BY
	akp.harvest_date,
	akp.company_odooid,
	akp.estate_odooid,
	akp.division_odooid,
	akp.block_odooid,
	block.planted_area,
	block.plant_total,
	bjr.bjr,
	rate.base_weight
;

