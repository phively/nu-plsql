/* CPI-U from https://data.bls.gov/cgi-bin/surveymost?bls, leveled at 1982-1984 = 100 */

-- Clear existing table
Drop Table tbl_cpi_u;

-- Definition for CPI-U table
Create Table tbl_cpi_u (
  calendar_year number, -- Year of CPI-U
  cpi_u_avg number, -- CPI-U numeric value, produced by averaging together the monthly levels through as_of
  as_of date -- Date through which CPI-U was averaged
);

-- Insert current cpi-u data
Insert All
  /* ADD ROWS HERE */
  Into tbl_cpi_u Values(2017, 244.62, to_date('20170930', 'yyyymmdd')) -- Through September; updated 2017-11-13
  Into tbl_cpi_u Values(2016, 240.007, to_date('20161231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2015, 237.017, to_date('20151231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2014, 236.736, to_date('20141231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2013, 232.957, to_date('20131231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2012, 229.594, to_date('20121231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2011, 224.939, to_date('20111231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2010, 218.056, to_date('20101231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2009, 214.537, to_date('20091231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2008, 215.303, to_date('20081231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2007, 207.342, to_date('20071231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2006, 201.6, to_date('20061231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2005, 195.3, to_date('20051231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2004, 188.9, to_date('20041231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2003, 184, to_date('20031231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2002, 179.9, to_date('20021231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2001, 177.1, to_date('20011231', 'yyyymmdd'))
  Into tbl_cpi_u Values(2000, 172.2, to_date('20001231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1999, 166.6, to_date('19991231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1998, 163, to_date('19981231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1997, 160.5, to_date('19971231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1996, 156.9, to_date('19961231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1995, 152.4, to_date('19951231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1994, 148.2, to_date('19941231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1993, 144.5, to_date('19931231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1992, 140.3, to_date('19921231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1991, 136.2, to_date('19911231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1990, 130.7, to_date('19901231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1989, 124, to_date('19891231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1988, 118.3, to_date('19881231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1987, 113.6, to_date('19871231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1986, 109.6, to_date('19861231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1985, 107.6, to_date('19851231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1984, 103.9, to_date('19841231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1983, 99.6, to_date('19831231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1982, 96.5, to_date('19821231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1981, 90.9, to_date('19811231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1980, 82.4, to_date('19801231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1979, 72.6, to_date('19791231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1978, 65.2, to_date('19781231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1977, 60.6, to_date('19771231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1976, 56.9, to_date('19761231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1975, 53.8, to_date('19751231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1974, 49.3, to_date('19741231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1973, 44.4, to_date('19731231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1972, 41.8, to_date('19721231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1971, 40.5, to_date('19711231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1970, 38.8, to_date('19701231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1969, 36.7, to_date('19691231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1968, 34.8, to_date('19681231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1967, 33.4, to_date('19671231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1966, 32.4, to_date('19661231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1965, 31.5, to_date('19651231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1964, 31, to_date('19641231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1963, 30.6, to_date('19631231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1962, 30.2, to_date('19621231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1961, 29.9, to_date('19611231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1960, 29.6, to_date('19601231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1959, 29.1, to_date('19591231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1958, 28.9, to_date('19581231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1957, 28.1, to_date('19571231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1956, 27.2, to_date('19561231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1955, 26.8, to_date('19551231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1954, 26.9, to_date('19541231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1953, 26.7, to_date('19531231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1952, 26.5, to_date('19521231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1951, 26.0, to_date('19511231', 'yyyymmdd'))
  Into tbl_cpi_u Values(1950, 24.1, to_date('19501231', 'yyyymmdd'))
-- Commit table
Select * From DUAL;
Commit Work;
-- Index on year
Create Index calendar_year On tbl_cpi_u(calendar_year);

-- Check results
Select *
From tbl_cpi_u;
