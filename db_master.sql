CREATE DATABASE DB_MASTER;

DROP TABLE IF EXISTS m_company CASCADE;
CREATE TABLE m_company (
    id INT4 PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    init VARCHAR,
    name VARCHAR NOT NULL,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP
);

DROP TABLE IF EXISTS m_operating_unit CASCADE;
CREATE TABLE m_operating_unit (
    id INT4 PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    company_id INT4 NOT NULL,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,
    
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id)
);

DROP TABLE IF EXISTS m_estate CASCADE;
CREATE TABLE m_estate (
    id INT4 PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    mark VARCHAR,
    is_pabrik BOOLEAN DEFAULT FALSE,
    is_nursery BOOLEAN DEFAULT FALSE,
    operating_unit_id INT4 NOT NULL,
    company_id INT4 NOT NULL,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,
    
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id),
    CONSTRAINT fk_operating_unit FOREIGN KEY (operating_unit_id) REFERENCES m_operating_unit(id) 
);

DROP TABLE IF EXISTS m_division CASCADE;
CREATE TABLE m_division (
    id INT4 PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    mark VARCHAR,
    operating_unit_id INT4 NOT NULL,
    company_id INT4 NOT NULL,
    estate_id INT4 NOT NULL,
    parent_id INT4,
	asisten_kepala_id INT4,
	asisten_id INT4,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,
    
    CONSTRAINT fk_operating_unit FOREIGN KEY (operating_unit_id) REFERENCES m_operating_unit(id),
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id),
    CONSTRAINT fk_estate FOREIGN KEY (estate_id) REFERENCES m_estate(id),
    CONSTRAINT fk_parent FOREIGN KEY (parent_id) REFERENCES m_division(id),
    CONSTRAINT fk_asisten_kepala FOREIGN KEY (asisten_kepala_id) REFERENCES m_employee(id),
    CONSTRAINT fk_asisten FOREIGN KEY (asisten_id) REFERENCES m_employee(id)
);

DROP TABLE IF EXISTS m_department CASCADE;
CREATE TABLE m_department (
    id INT4 PRIMARY KEY,
    code VARCHAR,
    name VARCHAR NOT NULL,
    complete_name VARCHAR NOT NULL,
    operating_unit_id INT4,
    company_id INT4 NOT NULL,
    parent_id INT4,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,
    
    CONSTRAINT fk_operating_unit FOREIGN KEY (operating_unit_id) REFERENCES m_operating_unit(id),
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id),
    CONSTRAINT fk_parent FOREIGN KEY (parent_id) REFERENCES m_department(id)
);

DROP TABLE IF EXISTS m_block CASCADE;
CREATE TABLE m_block (
    id INT4 PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    code2 VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    topograph VARCHAR,
    soil VARCHAR,
    is_plasma BOOLEAN DEFAULT FALSE,
    plasma_owner VARCHAR,
    area_coefficient FLOAT8,
    block_area FLOAT8,
    planted_area FLOAT8,
    plant_total INT4,
    maturate_time INT4,
    planted_date DATE,
    mature_date DATE,
    mature_age INT4,
    immature_age INT4,
    is_dummmy BOOLEAN DEFAULT FALSE,    
    operating_unit_id INT4 NOT NULL,
    company_id INT4 NOT NULL,
    estate_id INT4 NOT NULL,
    division_id INT4 NOT NULL,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,
    
    CONSTRAINT fk_operating_unit FOREIGN KEY (operating_unit_id) REFERENCES m_operating_unit(id),
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id),
    CONSTRAINT fk_estate FOREIGN KEY (estate_id) REFERENCES m_estate(id),
    CONSTRAINT fk_division FOREIGN KEY (division_id) REFERENCES m_division(id)
);

DROP TABLE IF EXISTS m_tph CASCADE;
CREATE TABLE m_tph (
    id INT4 PRIMARY KEY,
    code VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    lat FLOAT NOT NULL DEFAULT 0.0,
    long FLOAT NOT NULL DEFAULT 0.0,
    lat_adj INT NOT NULL DEFAULT 0,
	long_adj INT NOT NULL DEFAULT 0,
    operating_unit_id INT4 NOT NULL,
    company_id INT4 NOT NULL,
    estate_id INT4 NOT NULL,
    division_id INT4 NOT NULL,
    block_id INT4 NOT NULL,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,
    
    CONSTRAINT fk_operating_unit FOREIGN KEY (operating_unit_id) REFERENCES m_operating_unit(id),
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id),
    CONSTRAINT fk_estate FOREIGN KEY (estate_id) REFERENCES m_estate(id),
    CONSTRAINT fk_division FOREIGN KEY (division_id) REFERENCES m_division(id),
    CONSTRAINT fk_block FOREIGN KEY (block_id) REFERENCES m_block(id)    
);

DROP TABLE IF EXISTS m_employee CASCADE;
CREATE TABLE m_employee (
	id INT4 PRIMARY KEY,
	nip VARCHAR NOT NULL,
	name VARCHAR NOT NULL,
	operating_unit_id INT4,
	company_id INT4 NOT NULL,
	estate_id INT4,
	division_id INT4,
	department_id INT4 NOT NULL,
	foreman_group_id INT4,
	foreman_id INT4,
	job_level_id INT4,
	job_level VARCHAR,
	job_id INT4 NOT NULL,
	job_name VARCHAR NOT NULL,
	type_id INT4 NOT NULL,
	type_name VARCHAR NOT NULL,
	status_id INT4 NOT NULL,
	job_status VARCHAR NOT NULL,
	fp_id INT4,
	gender VARCHAR,
	birthday DATE,
	id_number VARCHAR,
	work_date_start DATE,
	work_duration VARCHAR NOT NULL,
	contract_start DATE,
	contract_end DATE,
	contract_state VARCHAR,
	hr_transition VARCHAR,
	is_disabled BOOLEAN DEFAULT FALSE,
	create_by VARCHAR,
	create_date TIMESTAMP,
	write_by VARCHAR,
	write_date TIMESTAMP,
    
    CONSTRAINT fk_operating_unit FOREIGN KEY (operating_unit_id) REFERENCES m_operating_unit(id),
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id),
    CONSTRAINT fk_estate FOREIGN KEY (estate_id) REFERENCES m_estate(id),
    CONSTRAINT fk_division FOREIGN KEY (division_id) REFERENCES m_division(id),
    CONSTRAINT fk_department FOREIGN KEY (department_id) REFERENCES m_department(id)    
);

DROP TABLE IF EXISTS m_foreman_group CASCADE;
CREATE TABLE m_foreman_group (
    id INT4 PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    type VARCHAR NOT NULL,
    foreman_id INT4,
    foreman1_id INT4,
    kerani_id INT4,
    kerani1_id INT4,
    kerani_panen_id INT4,
    operating_unit_id INT4 NOT NULL,
    company_id INT4 NOT NULL,
    division_id INT4,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,
    
    CONSTRAINT fk_operating_unit FOREIGN KEY (operating_unit_id) REFERENCES m_operating_unit(id),
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id),
    CONSTRAINT fk_division FOREIGN KEY (division_id) REFERENCES m_division(id),
    CONSTRAINT fk_foreman FOREIGN KEY (foreman_id) REFERENCES m_employee(id),
    CONSTRAINT fk_foreman1 FOREIGN KEY (foreman1_id) REFERENCES m_employee(id),
    CONSTRAINT fk_kerani FOREIGN KEY (kerani_id) REFERENCES m_employee(id),
    CONSTRAINT fk_kerani1 FOREIGN KEY (kerani1_id) REFERENCES m_employee(id),
    CONSTRAINT fk_kerani_panen FOREIGN KEY (kerani_panen_id) REFERENCES m_employee(id)
);

DROP TABLE IF EXISTS m_equipment CASCADE;
CREATE TABLE m_equipment (
	id INT4 PRIMARY KEY, 
	code VARCHAR NOT NULL, 
	name VARCHAR NOT NULL, 
	asset_id INT4 NOT NULL, 
	class_id INT4, 
	class_type VARCHAR, 
	class_name VARCHAR, 
	note TEXT,
	model VARCHAR, 
	serial_no VARCHAR, 
	effective_date DATE NOT NULL, 
	company_id INT4 NOT NULL, 
	estate_id INT4, 
	warehouse_id INT4, 
	cost_center_id INT4, 
	owning_status_id INT4, 
	owner_id INT4, 
	brand_id INT4, 
	unit_model_id INT4, 
	machine_class_id INT4, 
	manufacturing_year VARCHAR, 
	engine_branch VARCHAR, 
	acquisition_date DATE, 
	measuring_type VARCHAR, 
	hourmeter INT4, 
	kilometer INT4, 
	operating_unit_id INT4,
	is_disabled BOOLEAN DEFAULT FALSE,
	create_by VARCHAR,
	create_date TIMESTAMP,
	write_by VARCHAR,
	write_date TIMESTAMP,
	
    CONSTRAINT fk_company FOREIGN KEY (company_id) REFERENCES m_company(id),
    CONSTRAINT fk_estate FOREIGN KEY (estate_id) REFERENCES m_estate(id),
    CONSTRAINT fk_operating_unit FOREIGN KEY (operating_unit_id) REFERENCES m_operating_unit(id) 
);

DROP TABLE IF EXISTS m_bjr CASCADE;
CREATE TABLE m_bjr (
    id INT4 PRIMARY KEY,
    block_id INT4 NOT NULL,
    period VARCHAR NOT NULL,
    weight NUMERIC(8,2) DEFAULT 0,
    bunches_qty INT4 NOT NULL DEFAULT 0,
    bjr NUMERIC(8,2) DEFAULT 0,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP
);

DROP TABLE IF EXISTS m_premi_rule CASCADE;
CREATE TABLE m_premi_rule (
	id INT4 PRIMARY KEY,
	name VARCHAR NOT NULL,
	date DATE,
	premi_loose_rate INT4 DEFAULT 0,
	premi_loose_rate2 INT4 DEFAULT 0,
	premi_doublebase_rate INT4 DEFAULT 0,
	additional_base_rate INT4 DEFAULT 0,
	operating_unit_id INT4 NOT NULL,
	company_id INT4 NOT NULL,	
	is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP
);

DROP TABLE IF EXISTS m_premi_rate CASCADE;
CREATE TABLE m_premi_rate (
	id INT4 PRIMARY KEY,
	rule_id INT4 NOT NULL,
	range_from NUMERIC(8,2) NOT NULL,
	range_to NUMERIC(8,2) NOT NULL,
	base_weight INT4 DEFAULT 0,
	rate1 INT4 DEFAULT 0,
	rate2 INT4 DEFAULT 0,
	rate3 INT4 DEFAULT 0,
	loose_rate1 INT4 DEFAULT 0,
	loose_rate2 INT4 DEFAULT 0,
	is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP,
    
	CONSTRAINT fk_premi_rule FOREIGN KEY (rule_id) REFERENCES m_premi_rule(id)
);

DROP TABLE IF EXISTS m_transporter CASCADE;
CREATE TABLE m_transporter (
    id INT4 PRIMARY KEY,
    code VARCHAR NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
	phone VARCHAR,
	mobile VARCHAR,
	email VARCHAR,
	address VARCHAR,
	city VARCHAR,
    is_disabled BOOLEAN DEFAULT FALSE,
    create_by VARCHAR,
    create_date TIMESTAMP,
    write_by VARCHAR,
    write_date TIMESTAMP
);

-- CREATE ACCESS TO ODOO GBS_PRD

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

DROP SERVER IF EXISTS gbs_prd_server CASCADE;
CREATE SERVER gbs_prd_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',
    dbname 'GBS_PRD',
    port '5432'
);

CREATE USER MAPPING FOR CURRENT_USER
SERVER gbs_prd_server
OPTIONS (
    user 'postgres',        -- user di GBS_PRD
    password 'gbsselaludihati' -- password user di GBS_PRD
);

IMPORT FOREIGN SCHEMA public
FROM SERVER gbs_prd_server
INTO public;

-- IMPORT DATA MASTER ODOO
-- Langkah: Import data backup ODOO GBS_PRD Server Production, ke LOCALHOST menggunakan PGAdmin4, format: plain, file: extract .tar.gz

-- company
UPDATE m_company SET is_disabled = TRUE;
INSERT INTO m_company (id, code, name, init, is_disabled, create_by, create_date, write_by, write_date)
SELECT a.id, a.code, a.name, NULL, FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    res_company a
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
ON CONFLICT (id) DO UPDATE
SET
    code = EXCLUDED.code,
    name = EXCLUDED.name,
    init = EXCLUDED.init,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;
UPDATE m_company SET init = 'GBS' WHERE id = 1;
UPDATE m_company SET init = 'LKK' WHERE id = 2;

-- operating_unit
UPDATE m_operating_unit SET is_disabled = TRUE;
INSERT INTO m_operating_unit (id, code, name, company_id, is_disabled, create_by, create_date, write_by, write_date)
SELECT a.id, a.code, a.name, a.company_id, FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    operating_unit a
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE a.active
ON CONFLICT (id) DO UPDATE
SET
    code = EXCLUDED.code,
    name = EXCLUDED.name,
    company_id = EXCLUDED.company_id,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- estate
UPDATE m_estate SET is_disabled = TRUE;
INSERT INTO m_estate (id, code, name, mark, is_pabrik, is_nursery, operating_unit_id, company_id, is_disabled, create_by, create_date, write_by, write_date)
SELECT a.id, a.code, a.name, a.mark, COALESCE(a.is_pabrik,FALSE), COALESCE(a.is_nursery,FALSE), a.operating_unit_id, a.company_id, FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    plantation_estate a
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE a.active
ON CONFLICT (id) DO UPDATE
SET
    code = EXCLUDED.code,
    name = EXCLUDED.name,
    mark = EXCLUDED.mark,
    is_pabrik = EXCLUDED.is_pabrik,
    is_nursery = EXCLUDED.is_nursery,
    operating_unit_id = EXCLUDED.operating_unit_id,
    company_id = EXCLUDED.company_id,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- divisi
UPDATE m_division SET is_disabled = TRUE;
INSERT INTO m_division (id, code, name, mark, operating_unit_id, company_id, estate_id, parent_id, is_disabled, create_by, create_date, write_by, write_date)
SELECT a.id, a.code, a.name, a.mark, a.operating_unit_id, a.company_id, a.estate_id, a.parent_division_id, FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    plantation_division a
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE a.active AND a.is_office = FALSE 
ON CONFLICT (id) DO UPDATE
SET
    code = EXCLUDED.code,
    name = EXCLUDED.name,
    mark = EXCLUDED.mark,
    operating_unit_id = EXCLUDED.operating_unit_id,
    company_id = EXCLUDED.company_id,
    estate_id = EXCLUDED.estate_id,
    parent_id = EXCLUDED.parent_id,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- department
UPDATE m_department SET is_disabled = TRUE;
INSERT INTO m_department (id, code, name, complete_name, operating_unit_id, company_id, parent_id, is_disabled, create_by, create_date, write_by, write_date)
SELECT a.id, NULL, a.name, a.complete_name, b.operating_unit_id, a.company_id, a.parent_id, FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    hr_department a
    LEFT JOIN plantation_division b ON b.id = a.division_id
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE a.active
ON CONFLICT (id) DO UPDATE
SET
    code = EXCLUDED.code,
    name = EXCLUDED.name,
    complete_name = EXCLUDED.complete_name,
    operating_unit_id = EXCLUDED.operating_unit_id,
    company_id = EXCLUDED.company_id,
    parent_id = EXCLUDED.parent_id,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- block
UPDATE m_block SET is_disabled = TRUE;
INSERT INTO m_block (
	id,code,code2,name,topograph,soil,is_plasma,plasma_owner,area_coefficient,block_area,planted_area,
	plant_total,maturate_time,planted_date,mature_date,mature_age,immature_age,is_dummmy,operating_unit_id,
	company_id,estate_id,division_id,is_disabled,create_by,create_date,write_by,write_date
)
SELECT 
	a.id, a.code, b.code, a.name, c.name, d.name, COALESCE(a.block_plasma,FALSE), e.name, a.area_coefficient, b.block_area, a.planted_area,
	a.plant_total,a.maturate_time_norm,a.planted_date,a.mature_date,a.plant_mature_age,a.plant_immature_age,a.is_dummy,a.operating_unit_id,
	a.company_id, a.estate_id, a.division_id, FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    plantation_land_planted a
    LEFT JOIN plantation_land_block b ON b.id = a.block_id
    LEFT JOIN plantation_land_topograph c ON c.id = b.topograph_id
    LEFT JOIN plantation_land_soil d ON d.id = b.soil_id
    LEFT JOIN res_partner e ON e.id = a.owner_plasma_id
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE a.active 
ON CONFLICT (id) DO UPDATE
SET
	code = EXCLUDED.code,
    code2 = EXCLUDED.code2,
    name = EXCLUDED.name,
    topograph = EXCLUDED.topograph,
    soil = EXCLUDED.soil,
    is_plasma = EXCLUDED.is_plasma,
    plasma_owner = EXCLUDED.plasma_owner,
    area_coefficient = EXCLUDED.area_coefficient,
    block_area = EXCLUDED.block_area,
    planted_area = EXCLUDED.planted_area,
    plant_total = EXCLUDED.plant_total,
    maturate_time = EXCLUDED.maturate_time,
    planted_date = EXCLUDED.planted_date,
    mature_date = EXCLUDED.mature_date,
    mature_age = EXCLUDED.mature_age,
    immature_age = EXCLUDED.immature_age,
    is_dummmy = EXCLUDED.is_dummmy,
    operating_unit_id = EXCLUDED.operating_unit_id,
    company_id = EXCLUDED.company_id,
    estate_id = EXCLUDED.estate_id,
    division_id = EXCLUDED.division_id,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- tph
UPDATE m_tph SET is_disabled = TRUE;
INSERT INTO m_tph (id,code,name,lat,long,lat_adj,long_adj,operating_unit_id,company_id,estate_id,division_id,block_id,is_disabled,create_by,create_date,write_by,write_date)
SELECT 
	a.id,REPLACE(a.name,' ',''),REPLACE(a.name,' ',''),0,0,0,0,a.operating_unit_id,a.company_id, b.estate_id, b.division_id, a.planted_block_id, FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    plantation_harvest_staging a
    LEFT JOIN plantation_land_planted b ON b.id = a.planted_block_id
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE a.active AND a.planted_block_id IS NOT NULL AND a.name IS NOT NULL
ON CONFLICT (id) DO UPDATE
SET
	code = EXCLUDED.code,
    name = EXCLUDED.name,
    lat = EXCLUDED.lat,
    long = EXCLUDED.long,
    operating_unit_id = EXCLUDED.operating_unit_id,
    company_id = EXCLUDED.company_id,
    estate_id = EXCLUDED.estate_id,
    division_id = EXCLUDED.division_id,
    block_id = EXCLUDED.block_id,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- m_employee
UPDATE m_employee SET is_disabled = TRUE;
INSERT INTO m_employee (
	id, nip, name, operating_unit_id, company_id, estate_id, division_id, department_id, foreman_group_id, foreman_id, job_level_id, job_level,
	job_id, job_name, type_id, type_name, status_id, job_status, fp_id, gender, birthday, id_number, work_date_start, work_duration,
	contract_start, contract_end, contract_state, hr_transition,
	is_disabled, create_by, create_date, write_by, write_date
)
SELECT 
	emp.id,
	emp.nomor_induk_pegawai AS nip,
	emp.name AS emp_name,
	emp.operating_unit_id,
	emp.company_id,
	div.estate_id,
	emp.division_id,
	emp.department_id,
	emp.foreman_group_id,
	emp.foreman_id,
	emp.job_level_id,
	lvl.name AS job_level,
	emp.job_id,
	job.name AS job_name,
	emp.employee_type_id AS type_id,
	typ.name AS employee_type,
	emp.employee_status_id AS status_id,
	sts.name AS job_status,
	emp.fp_id_emp,
	emp.gender,
	emp.birthday,
	emp.identification_id AS id_number,
	emp.work_date_start,
	emp.work_duration_string AS work_duration,
	ctract.date_start AS contract_start,
	ctract.date_end AS contract_end,
	ctract.state AS contract_state,
	ctract.hr_transition,
	FALSE,
	cu.login AS create_by,
	emp.create_date,
	wu.login AS write_by,
	emp.write_date
FROM
	hr_employee emp
	LEFT JOIN hr_department dept ON dept.id = emp.department_id
	LEFT JOIN plantation_division div ON div.id = emp.division_id
	LEFT JOIN hr_employee_type typ ON typ.id = emp.employee_type_id
	LEFT JOIN hr_job job ON job.id = emp.job_id
	LEFT JOIN hit_md_employee_status sts ON sts.id = emp.employee_status_id
	LEFT JOIN hit_md_job_level lvl ON lvl.id = emp.job_level_id
	LEFT JOIN hr_contract ctract ON ctract.id = emp.contract_id
	LEFT JOIN res_users cu ON cu.id = emp.create_uid
	LEFT JOIN res_users wu ON wu.id = emp.write_uid
WHERE emp.active AND emp.job_id IS NOT NULL 
ON CONFLICT (id) DO UPDATE
SET
	nip              = EXCLUDED.nip,
	name             = EXCLUDED.name,
	operating_unit_id = EXCLUDED.operating_unit_id,
	company_id       = EXCLUDED.company_id,
	estate_id        = EXCLUDED.estate_id,
	division_id      = EXCLUDED.division_id,
	department_id    = EXCLUDED.department_id,
	foreman_group_id = EXCLUDED.foreman_group_id,
	foreman_id       = EXCLUDED.foreman_id,
	job_level_id     = EXCLUDED.job_level_id,
	job_level        = EXCLUDED.job_level,
	job_id           = EXCLUDED.job_id,
	job_name         = EXCLUDED.job_name,
	type_id          = EXCLUDED.type_id,
	type_name        = EXCLUDED.type_name,
	status_id        = EXCLUDED.status_id,
	job_status       = EXCLUDED.job_status,
	fp_id			 = EXCLUDED.fp_id,
	gender           = EXCLUDED.gender,
	birthday         = EXCLUDED.birthday,
	id_number        = EXCLUDED.id_number,
	work_date_start  = EXCLUDED.work_date_start,
	work_duration    = EXCLUDED.work_duration,
	contract_start   = EXCLUDED.contract_start,
	contract_end     = EXCLUDED.contract_end,
	contract_state   = EXCLUDED.contract_state,
	hr_transition    = EXCLUDED.hr_transition,
	is_disabled      = FALSE,
	create_by        = EXCLUDED.create_by,
	create_date      = EXCLUDED.create_date,
	write_by         = EXCLUDED.write_by,
	write_date       = EXCLUDED.write_date
;

-- foreman group
UPDATE m_foreman_group SET is_disabled = TRUE;
INSERT INTO m_foreman_group (id, code, name, type, foreman_id, foreman1_id, kerani_id, kerani1_id, kerani_panen_id, operating_unit_id, company_id, division_id, is_disabled, create_by, create_date, write_by, write_date)
SELECT a.id, a.code, a.name, a.type, CASE WHEN c.id IS NULL THEN NULL ELSE a.foreman_id END, CASE WHEN d.id IS NULL THEN NULL ELSE a.foreman1_id END, a.kerani_id, a.kerani1_id, a.kerani_harvest_id, a.operating_unit_id, a.company_id, b.division_id, FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    hr_foreman_group a
    LEFT JOIN hr_department b ON b.id = a.department_id
    LEFT JOIN hr_employee c ON c.id = a.foreman_id AND c.active
    LEFT JOIN hr_employee d ON d.id = a.foreman1_id AND d.active
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE a.active 
ON CONFLICT (id) DO UPDATE
SET
    code              = EXCLUDED.code,
    name              = EXCLUDED.name,
    type              = EXCLUDED.type,
    foreman_id        = EXCLUDED.foreman_id,
    foreman1_id       = EXCLUDED.foreman1_id,
    kerani_id         = EXCLUDED.kerani_id,
    kerani1_id        = EXCLUDED.kerani1_id,
    kerani_panen_id   = EXCLUDED.kerani_panen_id,
    operating_unit_id = EXCLUDED.operating_unit_id,
    company_id        = EXCLUDED.company_id,
    division_id       = EXCLUDED.division_id,
    is_disabled       = FALSE,
    create_by         = EXCLUDED.create_by,
    create_date       = EXCLUDED.create_date,
    write_by          = EXCLUDED.write_by,
    write_date        = EXCLUDED.write_date
;

-- m_equipment
UPDATE m_equipment SET is_disabled = TRUE;
INSERT INTO m_equipment (
	id, code, name, asset_id, class_id, class_type, class_name, note, model, serial_no, effective_date,
	company_id, estate_id, warehouse_id, cost_center_id, owning_status_id, owner_id, brand_id, unit_model_id,
	machine_class_id, manufacturing_year, engine_branch, acquisition_date, measuring_type, hourmeter, 
	kilometer, operating_unit_id, is_disabled, create_by, create_date, write_by, write_date
	)
SELECT
	a.id, a.name, a.equipment_name, a.asset_id, a.equipment_class_id, c.class_id, c.name, a.note, a.model, a.serial_no, a.effective_date, 
	b.company_id, b.plantation_estate_id, a.warehouse_id, a.cost_center_id, a.owning_status_id, a.owner_id, a.brand_id, a.unit_model_id, 
	a.machine_class_id, a.manufacturing_year, a.engine_branch, a.acquisition_date, a.measuring_type, a.hourmeter, 
  	a.kilometer, NULL, FALSE, x.login, a.create_date, y.login, a.write_date
  	
FROM
	maintenance_equipment a 
	LEFT JOIN plantation_cost_center b ON b.id = a.cost_center_id 
	LEFT JOIN maintenance_class_equipment_type c ON c.id = a.equipment_class_id 
	LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE
	b.id IS NOT NULL 
ON CONFLICT (id) DO UPDATE
SET
	code = EXCLUDED.code, 
	name = EXCLUDED.name, 
	asset_id = EXCLUDED.asset_id, 
	class_id = EXCLUDED.class_id, 
	class_type = EXCLUDED.class_type, 
	class_name = EXCLUDED.class_name, 
	note = EXCLUDED.note,
	model = EXCLUDED.model, 
	serial_no = EXCLUDED.serial_no, 
	effective_date = EXCLUDED.effective_date, 
	company_id = EXCLUDED.company_id, 
	estate_id = EXCLUDED.estate_id, 
	warehouse_id = EXCLUDED.warehouse_id, 
	cost_center_id = EXCLUDED.cost_center_id, 
	owning_status_id = EXCLUDED.owning_status_id, 
	owner_id = EXCLUDED.owner_id, 
	brand_id = EXCLUDED.brand_id, 
	unit_model_id = EXCLUDED.unit_model_id, 
	machine_class_id = EXCLUDED.machine_class_id, 
	manufacturing_year = EXCLUDED.manufacturing_year, 
	engine_branch = EXCLUDED.engine_branch, 
	acquisition_date = EXCLUDED.acquisition_date, 
	measuring_type = EXCLUDED.measuring_type, 
	hourmeter = EXCLUDED.hourmeter, 
	kilometer = EXCLUDED.kilometer, 
	operating_unit_id = EXCLUDED.operating_unit_id,
	is_disabled = FALSE,
	create_by = EXCLUDED.create_by,
	create_date = EXCLUDED.create_date,
	write_by = EXCLUDED.write_by,
	write_date = EXCLUDED.write_date
;

-- m_bjr
UPDATE m_bjr SET is_disabled = TRUE;
INSERT INTO m_bjr (id, block_id, period, weight, bunches_qty, bjr, is_disabled, create_by, create_date, write_by, write_date)
SELECT
	a.id,
	a.planted_block_id,
	b.tahun_kalkulasi || RIGHT('00' || b.periode_kalkulasi,2) period,
	a.delivered_bunches_est_weight weight,
	a.delivered_bunches_qty bunches_qty,
	a.new_avg_weight_ffb bjr,
	FALSE, x.login, a.create_date, y.login, a.write_date
FROM
	plantation_batch_average_ffb_line a
	LEFT JOIN plantation_batch_average_ffb b ON b.id = a.batch_id  
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
ON CONFLICT (id) DO UPDATE
SET
    block_id = EXCLUDED.block_id,
    period = EXCLUDED.period,
    weight = EXCLUDED.weight,
    bunches_qty = EXCLUDED.bunches_qty,
    bjr = EXCLUDED.bjr,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- m_premi_rule
UPDATE m_premi_rule SET is_disabled = TRUE;
INSERT INTO m_premi_rule (id, name, date, premi_loose_rate, premi_loose_rate2, premi_doublebase_rate, additional_base_rate, operating_unit_id, company_id, is_disabled, create_by, create_date, write_by, write_date)
SELECT
	a.id,
	a.name,
	a.date,
	a.premi_ffb_loose_rate,
	a.premi_ffb_loose_rate_2,
	a.premi_double_base_achieved_rate,
	a.additional_base_for_panen_without_loose,
	a.operating_unit_id,
	a.company_id,
	FALSE, x.login, a.create_date, y.login, a.write_date
FROM
	plantation_harvest_premi_rule a
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE a.active
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    date = EXCLUDED.date,
    premi_loose_rate = EXCLUDED.premi_loose_rate,
    premi_loose_rate2 = EXCLUDED.premi_loose_rate2,
    premi_doublebase_rate = EXCLUDED.premi_doublebase_rate,
    additional_base_rate = EXCLUDED.additional_base_rate,
    operating_unit_id = EXCLUDED.operating_unit_id,
    company_id = EXCLUDED.company_id,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- m_premi_rate
UPDATE m_premi_rate SET is_disabled = TRUE;
INSERT INTO m_premi_rate (id, rule_id, range_from, range_to, base_weight, rate1, rate2, rate3, loose_rate1, loose_rate2, is_disabled, create_by, create_date, write_by, write_date)
SELECT
	a.id,
	a.rule_id,
	a.avg_ffb_range_from,
	a.avg_ffb_range_to,
	a.base_weight,
	a.rate_1,
	a.rate_2,
	a.rate_3,
	a.loose_rate_1,
	a.loose_rate_2,
	FALSE, x.login, a.create_date, y.login, a.write_date
FROM
	plantation_harvest_premi_rate a
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
ON CONFLICT (id) DO UPDATE
SET
    rule_id = EXCLUDED.rule_id,
    range_from = EXCLUDED.range_from,
    range_to = EXCLUDED.range_to,
    base_weight = EXCLUDED.base_weight,
    rate1 = EXCLUDED.rate1,
    rate2 = EXCLUDED.rate2,
    rate3 = EXCLUDED.rate3,
    loose_rate1 = EXCLUDED.loose_rate1,
    loose_rate2 = EXCLUDED.loose_rate2,
    is_disabled = FALSE,
    create_by = EXCLUDED.create_by,
    create_date = EXCLUDED.create_date,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;

-- m_transporter
UPDATE m_transporter SET is_disabled = TRUE;
INSERT INTO m_transporter (id, code, name, phone, mobile, email, address, city, is_disabled, create_by, create_date, write_by, write_date)
SELECT
    a.id,
    a.vendor_code,
    a.name,
    a.phone,
    a.mobile,
    a.email,
    a.contact_address_complete,
    a.city,
    FALSE, x.login, a.create_date, y.login, a.write_date
FROM
    res_partner a
    LEFT JOIN res_partner_res_partner_category_rel b ON b.partner_id = a.id
    LEFT JOIN res_users x ON x.id = a.create_uid
    LEFT JOIN res_users y ON y.id = a.write_uid
WHERE
    a.active = TRUE
    AND a.vendor_code IS NOT NULL
    AND a.category_id = 6
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    mobile = EXCLUDED.mobile,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    city = EXCLUDED.city,
    is_disabled = EXCLUDED.is_disabled,
    write_by = EXCLUDED.write_by,
    write_date = EXCLUDED.write_date
;
