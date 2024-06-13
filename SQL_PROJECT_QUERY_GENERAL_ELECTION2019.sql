-- creating database
create database election_db;
use election_db;
-- creating schema of the table 
create table election_detail(STATE varchar(50), 
CONSTITUENCY varchar(50),
NAME varchar(50),
WINNER int,
PARTY varchar(100),
SYMBOL varchar(100),
GENDER char(10), 
CRIMINALCASES varchar(50),
AGE int,
CATEGORY char(50),
EDUCATION char(50),
ASSETS text, 
LIABILITIES	text, 
GENERALVOTES int,	
POSTALVOTES	int,
TOTALVOTES int,	
PERC_OVER_TOTAL_ELECTORS double,
PERC_OVER_TOTAL_VOTES_POLLED double,
TOTALELECTORS int
);

-- checking contents of the data
select * from election_detail;
select distinct education from election_detail;
use election_db;

-- To do some analysis on the data lets go for some data cleaning

-- cleaning the assets column
-- Step 1: Extract numeric part using SUBSTRING_INDEX and replace
SELECT
  assets,
  replace(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(assets, 'Rs ', -1), '\n', 1)), ',', '')
FROM election_detail;

-- Step 2: 
-- Create a new column to store the integer value
ALTER TABLE election_detail ADD COLUMN assets_int bigINT;

-- Update the new column with the extracted integer values
UPDATE election_detail
SET assets_int = CAST(REPLACE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(assets, 'Rs ', -1), '\n', 1)), ',', '') AS UNSIGNED)
WHERE assets IS NOT NULL 
  AND TRIM(assets) != ''
  AND REPLACE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(assets, 'Rs ', -1), '\n', 1)), ',', '') REGEXP '^[0-9]+$';
  
-- cleaning the liabilities column
 UPDATE election_detail
SET liabilities_int = CAST(REPLACE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(liabilities, 'Rs ', -1), '\n', 1)), ',', '') AS UNSIGNED)
WHERE liabilities IS NOT NULL 
  AND TRIM(liabilities) != ''
  AND REPLACE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(liabilities, 'Rs ', -1), '\n', 1)), ',', '') REGEXP '^[0-9]+$';
  
  -- cleaning the education column("post graduate\n" to "post graduate")
  update election_detail set education = 'Post Graduate'
  where education = 'Post Graduate\n';
  
  -- cleaning and updating the criminal cases column from text to int
  alter table election_detail add column criminal_cases int;
update election_detail set criminal_cases= cast(criminalcases as unsigned)
WHERE criminalcases IS NOT NULL 
  AND TRIM(criminalcases) != ''
  AND criminalcases REGEXP '^[0-9]+$';

set sql_safe_updates = 0;

-- The Analysis
-- State and Constituency Level Analysis

-- What is the distribution of Constituencies over all the states?
select State, count(distinct constituency) as Constituency
from election_detail
group by state
order by count(distinct constituency) desc;

-- Party Level Analysis

-- Which Parties have been present in most constituencies and States
SELECT
    PARTY,
    COUNT(DISTINCT CONSTITUENCY) AS CONSTITUENCIES_CONTESTED,
    COUNT(DISTINCT STATE) AS STATES_CONTESTED
FROM
    election_detail
GROUP BY
    PARTY
ORDER BY
    CONSTITUENCIES_CONTESTED DESC,
    STATES_CONTESTED DESC;

-- What has been the performance of the Parties Statewise?
SELECT 
    STATE,
    PARTY,
    COUNT(CASE WHEN WINNER = 1 THEN 1 END) AS SEATS_WON,
    SUM(TOTALVOTES) AS TOTAL_VOTES
FROM 
    election_detail
GROUP BY 
    STATE,
    PARTY
ORDER BY 
    STATE,
    TOTAL_VOTES DESC;


SELECT 
    STATE,
    SUM(CASE WHEN PARTY = 'BJP' THEN CASE WHEN WINNER = 1 THEN 1 ELSE 0 END ELSE 0 END) AS BJP,
    SUM(CASE WHEN PARTY = 'TRS' THEN CASE WHEN WINNER = 1 THEN 1 ELSE 0 END ELSE 0 END) AS TRS,
    SUM(CASE WHEN PARTY = 'INC' THEN CASE WHEN WINNER = 1 THEN 1 ELSE 0 END ELSE 0 END) AS INC,
    SUM(CASE WHEN PARTY = 'NOTA' THEN CASE WHEN WINNER = 1 THEN 1 ELSE 0 END ELSE 0 END) AS NOTA
FROM 
    election_detail
GROUP BY 
    STATE
ORDER BY 
    STATE;
    
    
-- Which party has won the most constituencies?
select party, count(case when winner= 1 then 1 end) as constituencies_won
from election_detail
group by party
order by  constituencies_won desc;


/* What has been the general Win vs Loss relationship for the Parties in 2019? */
SELECT 
    PARTY,
    SUM(CASE WHEN WINNER = 1 THEN 1 ELSE 0 END) AS WINS,
    SUM(CASE WHEN WINNER = 0 THEN 1 ELSE 0 END) AS LOSSES
FROM 
    election_detail
GROUP BY 
    PARTY
ORDER BY 
    WINS DESC, LOSSES ASC;
    
-- Politician Level Analytics

-- What is the Gender Ratio of the Contestants? Also the Gender Ratio of the Winners?
SELECT GENDER, 
SUM(CASE WHEN WINNER = 1 THEN 1 ELSE 0 END) AS WINS,
SUM(CASE WHEN WINNER = 0 THEN 1 ELSE 0 END) AS LOSSES
FROM ELECTION_DETAIL
GROUP BY GENDER
HAVING GENDER != "";

-- What is the Educational Qualification of our politicians?
SELECT EDUCATION, COUNT(*)
FROM ELECTION_DETAIL
where Winner = 1
GROUP BY EDUCATION
HAVING EDUCATION != "";

SELECT EDUCATION, COUNT(*)
FROM ELECTION_DETAIL
GROUP BY EDUCATION
HAVING EDUCATION != "";

-- What is the relationship of Age and Politics?
SELECT GENDER,
    CASE
        WHEN AGE BETWEEN 20 AND 29 THEN '20-29'
        WHEN AGE BETWEEN 30 AND 39 THEN '30-39'
        WHEN AGE BETWEEN 40 AND 49 THEN '40-49'
        WHEN AGE BETWEEN 50 AND 59 THEN '50-59'
        WHEN AGE BETWEEN 60 AND 69 THEN '60-69'
        WHEN AGE BETWEEN 70 AND 79 THEN '70-79'
        ELSE '80+' 
    END AS AGE_GROUP,
    COUNT(*) AS TOTAL_CANDIDATES,
    SUM(CASE WHEN WINNER = 1 THEN 1 ELSE 0 END) AS WINNERS,
    SUM(CASE WHEN WINNER = 0 THEN 1 ELSE 0 END) AS LOSERS
FROM 
    election_detail
GROUP BY GENDER,
    CASE
        WHEN AGE BETWEEN 20 AND 29 THEN '20-29'
        WHEN AGE BETWEEN 30 AND 39 THEN '30-39'
        WHEN AGE BETWEEN 40 AND 49 THEN '40-49'
        WHEN AGE BETWEEN 50 AND 59 THEN '50-59'
        WHEN AGE BETWEEN 60 AND 69 THEN '60-69'
        WHEN AGE BETWEEN 70 AND 79 THEN '70-79'
        ELSE '80+' 
    END
HAVING GENDER != ''
ORDER BY 
    AGE_GROUP;

-- What relation does the Politician category have with the election results?
SELECT CATEGORY, 
 COUNT(*) AS TOTAL_CANDIDATES,
    SUM(CASE WHEN WINNER = 1 THEN 1 ELSE 0 END) AS WINNERS
FROM ELECTION_DETAIL
GROUP BY CATEGORY
HAVING CATEGORY != "";

-- Have the politicians been involved with criminal activities?
select  party, count(criminal_cases)
from election_detail
where criminal_cases > 0
group by party
order by count(criminal_cases) desc;
-- the person with the most criminal cases is K SURENDRAN with 240 cases representing the party BJP


-- lets do some more analysis using criminal_cases
-- combined sum of candidates with criminal_cases partywise
with c as (select name, criminal_cases, party
from election_detail
where criminal_cases > 0)
select distinct party, count(name) over (partition by party) as combined_total_of_parties
from c
order by combined_total_of_parties desc;


-- Plotting the Assets vs Liabilities amount for Winning Politicians 
select state, assets_int, liabilities_int, name, party, constituency
from election_detail
where winner= 1
order by assets_int desc, liabilities_int desc;


