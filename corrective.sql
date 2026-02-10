-- MENAMBAHKAN PEMANEN KE RKH YANG SUDAH DI CLOSE

-- cari ID pemanen yang dimaksud
SELECT * FROM m_employee WHERE name ILIKE '%bambang%' AND job_name = 'Pemanen' AND division_id = 63;

-- cari RKH yang dimaksud
SELECT
	harv.*
FROM 
	t_harvester harv
	LEFT JOIN t_foreman fore ON fore.id = harv.foreman_id
WHERE
	fore.rkh_id = '4a44658f-d96e-4108-b114-6e835e609b48'
	AND harv.foreman_id = 'dcee298e-0197-4c38-8737-82387aaa3c11'
;

-- insert data absen sesuai RKH dan Pemanen yang dimaksud
INSERT INTO t_harvester (
	id, foreman_id, emp_id, nip, fp_id, name, job_level_id, job_level_name, job_id, job_name,
	is_asistensi, profile_id, date_sync, sync_attempt, create_by, create_date, write_by, write_date, is_kutip_required
) 
SELECT 
	gen_random_uuid(),
	h.foreman_id,
	e.id,
	e.nip,
	e.fp_id,
	e.name,
	e.job_level_id,
	e.job_level,
	e.job_id,
	e.job_name,
	FALSE,
	h.profile_id,
	h.date_sync,
	h.sync_attempt,
	'Administrator',
	h.create_date,
	'Administrator',
	h.write_date,
	h.is_kutip_required 
FROM
	t_harvester h
	LEFT JOIN m_employee e ON e.id = 23474
WHERE 
	h.id = '4cf7b35e-c88d-4cb1-a6e3-b92d6ced955b'
;
