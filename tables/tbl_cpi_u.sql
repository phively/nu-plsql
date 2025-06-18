/* CPI-U from https://data.bls.gov/cgi-bin/surveymost?bls, leveled at 1982-1984 = 100 */
-- https://data.bls.gov/timeseries/CUUR0000SA0?years_option=all_years
-- Aug 2024: https://data.bls.gov/timeseries/CUUR0000SA0?years_option=all_years

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
Into tbl_cpi_u Values(1913, 9.88333333333333,  to_date('19131231', 'yyyymmdd'))
Into tbl_cpi_u Values(1914, 10.0166666666667,  to_date('19141231', 'yyyymmdd'))
Into tbl_cpi_u Values(1915, 10.1083333333333,  to_date('19151231', 'yyyymmdd'))
Into tbl_cpi_u Values(1916, 10.8833333333333,  to_date('19161231', 'yyyymmdd'))
Into tbl_cpi_u Values(1917, 12.825,  to_date('19171231', 'yyyymmdd'))
Into tbl_cpi_u Values(1918, 15.0416666666667,  to_date('19181231', 'yyyymmdd'))
Into tbl_cpi_u Values(1919, 17.3333333333333,  to_date('19191231', 'yyyymmdd'))
Into tbl_cpi_u Values(1920, 20.0416666666667,  to_date('19201231', 'yyyymmdd'))
Into tbl_cpi_u Values(1921, 17.85,  to_date('19211231', 'yyyymmdd'))
Into tbl_cpi_u Values(1922, 16.75,  to_date('19221231', 'yyyymmdd'))
Into tbl_cpi_u Values(1923, 17.05,  to_date('19231231', 'yyyymmdd'))
Into tbl_cpi_u Values(1924, 17.125,  to_date('19241231', 'yyyymmdd'))
Into tbl_cpi_u Values(1925, 17.5416666666667,  to_date('19251231', 'yyyymmdd'))
Into tbl_cpi_u Values(1926, 17.7,  to_date('19261231', 'yyyymmdd'))
Into tbl_cpi_u Values(1927, 17.3583333333333,  to_date('19271231', 'yyyymmdd'))
Into tbl_cpi_u Values(1928, 17.1583333333333,  to_date('19281231', 'yyyymmdd'))
Into tbl_cpi_u Values(1929, 17.1583333333333,  to_date('19291231', 'yyyymmdd'))
Into tbl_cpi_u Values(1930, 16.7,  to_date('19301231', 'yyyymmdd'))
Into tbl_cpi_u Values(1931, 15.2083333333333,  to_date('19311231', 'yyyymmdd'))
Into tbl_cpi_u Values(1932, 13.6416666666667,  to_date('19321231', 'yyyymmdd'))
Into tbl_cpi_u Values(1933, 12.9333333333333,  to_date('19331231', 'yyyymmdd'))
Into tbl_cpi_u Values(1934, 13.3833333333333,  to_date('19341231', 'yyyymmdd'))
Into tbl_cpi_u Values(1935, 13.725,  to_date('19351231', 'yyyymmdd'))
Into tbl_cpi_u Values(1936, 13.8666666666667,  to_date('19361231', 'yyyymmdd'))
Into tbl_cpi_u Values(1937, 14.3833333333333,  to_date('19371231', 'yyyymmdd'))
Into tbl_cpi_u Values(1938, 14.0916666666667,  to_date('19381231', 'yyyymmdd'))
Into tbl_cpi_u Values(1939, 13.9083333333333,  to_date('19391231', 'yyyymmdd'))
Into tbl_cpi_u Values(1940, 14.0083333333333,  to_date('19401231', 'yyyymmdd'))
Into tbl_cpi_u Values(1941, 14.725,  to_date('19411231', 'yyyymmdd'))
Into tbl_cpi_u Values(1942, 16.3333333333333,  to_date('19421231', 'yyyymmdd'))
Into tbl_cpi_u Values(1943, 17.3083333333333,  to_date('19431231', 'yyyymmdd'))
Into tbl_cpi_u Values(1944, 17.5916666666667,  to_date('19441231', 'yyyymmdd'))
Into tbl_cpi_u Values(1945, 17.9916666666667,  to_date('19451231', 'yyyymmdd'))
Into tbl_cpi_u Values(1946, 19.5166666666667,  to_date('19461231', 'yyyymmdd'))
Into tbl_cpi_u Values(1947, 22.325,  to_date('19471231', 'yyyymmdd'))
Into tbl_cpi_u Values(1948, 24.0416666666667,  to_date('19481231', 'yyyymmdd'))
Into tbl_cpi_u Values(1949, 23.8083333333333,  to_date('19491231', 'yyyymmdd'))
Into tbl_cpi_u Values(1950, 24.0666666666667,  to_date('19501231', 'yyyymmdd'))
Into tbl_cpi_u Values(1951, 25.9583333333333,  to_date('19511231', 'yyyymmdd'))
Into tbl_cpi_u Values(1952, 26.55,  to_date('19521231', 'yyyymmdd'))
Into tbl_cpi_u Values(1953, 26.7666666666667,  to_date('19531231', 'yyyymmdd'))
Into tbl_cpi_u Values(1954, 26.85,  to_date('19541231', 'yyyymmdd'))
Into tbl_cpi_u Values(1955, 26.775,  to_date('19551231', 'yyyymmdd'))
Into tbl_cpi_u Values(1956, 27.1833333333333,  to_date('19561231', 'yyyymmdd'))
Into tbl_cpi_u Values(1957, 28.0916666666667,  to_date('19571231', 'yyyymmdd'))
Into tbl_cpi_u Values(1958, 28.8583333333333,  to_date('19581231', 'yyyymmdd'))
Into tbl_cpi_u Values(1959, 29.15,  to_date('19591231', 'yyyymmdd'))
Into tbl_cpi_u Values(1960, 29.575,  to_date('19601231', 'yyyymmdd'))
Into tbl_cpi_u Values(1961, 29.8916666666667,  to_date('19611231', 'yyyymmdd'))
Into tbl_cpi_u Values(1962, 30.25,  to_date('19621231', 'yyyymmdd'))
Into tbl_cpi_u Values(1963, 30.625,  to_date('19631231', 'yyyymmdd'))
Into tbl_cpi_u Values(1964, 31.0166666666667,  to_date('19641231', 'yyyymmdd'))
Into tbl_cpi_u Values(1965, 31.5083333333333,  to_date('19651231', 'yyyymmdd'))
Into tbl_cpi_u Values(1966, 32.4583333333333,  to_date('19661231', 'yyyymmdd'))
Into tbl_cpi_u Values(1967, 33.3583333333333,  to_date('19671231', 'yyyymmdd'))
Into tbl_cpi_u Values(1968, 34.7833333333333,  to_date('19681231', 'yyyymmdd'))
Into tbl_cpi_u Values(1969, 36.6833333333333,  to_date('19691231', 'yyyymmdd'))
Into tbl_cpi_u Values(1970, 38.825,  to_date('19701231', 'yyyymmdd'))
Into tbl_cpi_u Values(1971, 40.4916666666667,  to_date('19711231', 'yyyymmdd'))
Into tbl_cpi_u Values(1972, 41.8166666666667,  to_date('19721231', 'yyyymmdd'))
Into tbl_cpi_u Values(1973, 44.4,  to_date('19731231', 'yyyymmdd'))
Into tbl_cpi_u Values(1974, 49.3083333333333,  to_date('19741231', 'yyyymmdd'))
Into tbl_cpi_u Values(1975, 53.8166666666667,  to_date('19751231', 'yyyymmdd'))
Into tbl_cpi_u Values(1976, 56.9083333333333,  to_date('19761231', 'yyyymmdd'))
Into tbl_cpi_u Values(1977, 60.6083333333333,  to_date('19771231', 'yyyymmdd'))
Into tbl_cpi_u Values(1978, 65.2333333333333,  to_date('19781231', 'yyyymmdd'))
Into tbl_cpi_u Values(1979, 72.575,  to_date('19791231', 'yyyymmdd'))
Into tbl_cpi_u Values(1980, 82.4083333333333,  to_date('19801231', 'yyyymmdd'))
Into tbl_cpi_u Values(1981, 90.925,  to_date('19811231', 'yyyymmdd'))
Into tbl_cpi_u Values(1982, 96.5,  to_date('19821231', 'yyyymmdd'))
Into tbl_cpi_u Values(1983, 99.6,  to_date('19831231', 'yyyymmdd'))
Into tbl_cpi_u Values(1984, 103.883333333333,  to_date('19841231', 'yyyymmdd'))
Into tbl_cpi_u Values(1985, 107.566666666667,  to_date('19851231', 'yyyymmdd'))
Into tbl_cpi_u Values(1986, 109.608333333333,  to_date('19861231', 'yyyymmdd'))
Into tbl_cpi_u Values(1987, 113.625,  to_date('19871231', 'yyyymmdd'))
Into tbl_cpi_u Values(1988, 118.258333333333,  to_date('19881231', 'yyyymmdd'))
Into tbl_cpi_u Values(1989, 123.966666666667,  to_date('19891231', 'yyyymmdd'))
Into tbl_cpi_u Values(1990, 130.658333333333,  to_date('19901231', 'yyyymmdd'))
Into tbl_cpi_u Values(1991, 136.191666666667,  to_date('19911231', 'yyyymmdd'))
Into tbl_cpi_u Values(1992, 140.316666666667,  to_date('19921231', 'yyyymmdd'))
Into tbl_cpi_u Values(1993, 144.458333333333,  to_date('19931231', 'yyyymmdd'))
Into tbl_cpi_u Values(1994, 148.225,  to_date('19941231', 'yyyymmdd'))
Into tbl_cpi_u Values(1995, 152.383333333333,  to_date('19951231', 'yyyymmdd'))
Into tbl_cpi_u Values(1996, 156.85,  to_date('19961231', 'yyyymmdd'))
Into tbl_cpi_u Values(1997, 160.516666666667,  to_date('19971231', 'yyyymmdd'))
Into tbl_cpi_u Values(1998, 163.008333333333,  to_date('19981231', 'yyyymmdd'))
Into tbl_cpi_u Values(1999, 166.575,  to_date('19991231', 'yyyymmdd'))
Into tbl_cpi_u Values(2000, 172.2,  to_date('20001231', 'yyyymmdd'))
Into tbl_cpi_u Values(2001, 177.066666666667,  to_date('20011231', 'yyyymmdd'))
Into tbl_cpi_u Values(2002, 179.875,  to_date('20021231', 'yyyymmdd'))
Into tbl_cpi_u Values(2003, 183.958333333333,  to_date('20031231', 'yyyymmdd'))
Into tbl_cpi_u Values(2004, 188.883333333333,  to_date('20041231', 'yyyymmdd'))
Into tbl_cpi_u Values(2005, 195.291666666667,  to_date('20051231', 'yyyymmdd'))
Into tbl_cpi_u Values(2006, 201.591666666667,  to_date('20061231', 'yyyymmdd'))
Into tbl_cpi_u Values(2007, 207.342416666667,  to_date('20071231', 'yyyymmdd'))
Into tbl_cpi_u Values(2008, 215.3025,  to_date('20081231', 'yyyymmdd'))
Into tbl_cpi_u Values(2009, 214.537,  to_date('20091231', 'yyyymmdd'))
Into tbl_cpi_u Values(2010, 218.0555,  to_date('20101231', 'yyyymmdd'))
Into tbl_cpi_u Values(2011, 224.939166666667,  to_date('20111231', 'yyyymmdd'))
Into tbl_cpi_u Values(2012, 229.593916666667,  to_date('20121231', 'yyyymmdd'))
Into tbl_cpi_u Values(2013, 232.957083333333,  to_date('20131231', 'yyyymmdd'))
Into tbl_cpi_u Values(2014, 236.736166666667,  to_date('20141231', 'yyyymmdd'))
Into tbl_cpi_u Values(2015, 237.017,  to_date('20151231', 'yyyymmdd'))
Into tbl_cpi_u Values(2016, 240.007166666667,  to_date('20161231', 'yyyymmdd'))
Into tbl_cpi_u Values(2017, 245.119583333333,  to_date('20171231', 'yyyymmdd'))
Into tbl_cpi_u Values(2018, 251.106833333333,  to_date('20181231', 'yyyymmdd'))
Into tbl_cpi_u Values(2019, 255.657416666667,  to_date('20191231', 'yyyymmdd'))
Into tbl_cpi_u Values(2020, 258.811166666667,  to_date('20201231', 'yyyymmdd'))
Into tbl_cpi_u Values(2021, 270.96975,  to_date('20211231', 'yyyymmdd'))
Into tbl_cpi_u Values(2022, 292.654916666667,  to_date('20221231', 'yyyymmdd'))
Into tbl_cpi_u Values(2023, 304.701583333333,  to_date('20231231', 'yyyymmdd'))
Into tbl_cpi_u Values(2024, 314.54,  to_date('20240731', 'yyyymmdd')) -- As of July 31
-- Commit table
Select * From DUAL;
Commit Work;
-- Index on year
Create Index calendar_year On tbl_cpi_u(calendar_year);

-- Check results
Select *
From tbl_cpi_u;
