-- creating table for election results 2024
create table election_results_2024( 
	constituency varchar(100), 
	state varchar(1000), 
	status text, 
    Vote int, 
    Margin varchar(100), 
    Candidate varchar(100),
    Party varchar(100));
 use election_db ;
 
-- after importing the data using cmd, checking the data 
select * from election_results_2024 limit 100;

-- after checking data it is evident that the state column needs to be cleaned to make it usable
-- adding new column to store state names
alter table election_results_2024 add column new_state varchar(100);

-- Cleaning the state column using substring_index() and mid() 
select 
substring_index(mid(state, 
	locate('(', state, 1)+1) , ")", 1)
from election_results_2024;

-- now updating the new_state column with the cleaned values
update election_results_2024 
set new_state = trim(substring_index(mid(state, 
	locate('(', state, 1)+1) , ")", 1));
    
    
-- The Analysis
-- State and Constituency Level Analysis

-- What is the distribution of Constituencies over all the states?
select new_State, count(distinct constituency) as Constituency
from election_results_2024
group by new_state
order by count(distinct constituency) desc;

-- Party Level Analysis
-- Which Parties have been present in most constituencies and States
SELECT
    PARTY,
    COUNT(DISTINCT CONSTITUENCY) AS CONSTITUENCIES_CONTESTED,
    COUNT(DISTINCT New_STATE) AS STATES_CONTESTED
FROM
    election_results_2024
where party not like "None of the Above" and party not like "Independent"
GROUP BY
    PARTY
ORDER BY
    CONSTITUENCIES_CONTESTED DESC,
    STATES_CONTESTED DESC;
    
    
-- What has been the performance of the Parties Statewise?
SELECT 
    New_STATE,
    PARTY,
    COUNT(CASE WHEN status = "won" THEN 1 END) AS SEATS_WON,
    SUM(vote) AS TOTAL_VOTES
FROM 
    election_results_2024
GROUP BY 
    New_STATE,
    PARTY
ORDER BY 
    New_STATE,
    TOTAL_VOTES DESC;
    
    
-- Which party has won the most constituencies?
select party, COUNT(CASE WHEN status = "won" THEN 1 END) as constituencies_won
from election_results_2024
group by party
order by  constituencies_won desc;    


/* What has been the general Win vs Loss relationship for the Parties in 2019? */
SELECT 
    PARTY,
    SUM(CASE WHEN status = "won" THEN 1 ELSE 0 END) AS WINS,
    SUM(CASE WHEN status = "lost" THEN 1 ELSE 0 END) AS LOSSES
FROM 
    election_results_2024
GROUP BY 
    PARTY
ORDER BY 
    WINS DESC, LOSSES ASC;   
    
    
