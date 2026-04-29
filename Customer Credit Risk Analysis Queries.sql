USE Project
select*
from credit_risk
--C1 Do specific loan purposes (education, medical, personal, debt consolidation) lead to higher risk?
select loan_intent, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
group by loan_intent;
--C2 Do employment type and home ownership create differences in risk?
select person_home_ownership,employment_type, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
group by person_home_ownership,employment_type
order by default_percent desc;
--C3 How are the loan-to-income ratio and debt-to-income ratio related to repayment behavior?
with ratio as(
select person_home_ownership, case
			when loan_percent_income < 0.1 then 'Very Low'
			when loan_percent_income < 0.2 then 'Low'
			When loan_percent_income < 0.3 then 'Medium'
			else 'High'
		end as loan_income_group, 
		case
			when debt_to_income_ratio < 0.2 then 'Low'
			when debt_to_income_ratio < 0.4 then 'Medium'
			else 'High'
		end as debt_income_group, loan_status
from credit_risk
)
select loan_income_group, debt_income_group, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from ratio
group by loan_income_group, debt_income_group
order by default_percent desc
--C4 Which loan grades or terms appear to be safer, and which are riskier?
select loan_grade, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
group by loan_grade
order by default_percent desc;
--C5 Are there any clear differences among borrowers in the U.S., the U.K., and Canada?
select country, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
group by country
order by default_percent desc;
--C6 How do past delinquency history or long credit history affect loan outcomes?
with history as(
select case
			when cb_person_cred_hist_length <= 5 then '0-5'
			when cb_person_cred_hist_length <= 15 then '6-15'
			else '> 15'
		end as history_group, loan_status
from credit_risk
)
select history_group, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from history
group by history_group
order by default_percent desc;
--C7 How many customers are classified in loan grades A, B, or C (low-risk, low interest rates) but have a history of past default? What is the actual default rate of this group?
select cb_person_default_on_file, loan_grade, count(*) number_of_default, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
where loan_grade in ('A','B','C') and cb_person_default_on_file = 'Y'
group by cb_person_default_on_file, loan_grade
order by default_percent
--C8 How does the combined effect of debt burden (DTI) and home ownership status impact default risk?
with DTI as(
select person_home_ownership, 
		case
			when debt_to_income_ratio < 0.2 then 'Low'
			when debt_to_income_ratio < 0.4 then 'Medium'
			else 'High'
		end as debt_income_group, loan_status
from credit_risk
)
select person_home_ownership, debt_income_group, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from DTI
group by person_home_ownership, debt_income_group
order by default_percent desc;
--C9 What is the average interest rate difference between defaulting and non-defaulting borrowers within the same loan grade?
select loan_grade, 
		round(avg(case when loan_status = 1 then loan_int_rate end),2) avg_int_default, 
		round(avg(case when loan_status = 0 then loan_int_rate end),2) avg_int_non_default, 
		round(avg(case when loan_status = 1 then loan_int_rate end) - avg(case when loan_status = 0 then loan_int_rate end),2) rate_diff  
from credit_risk
group by loan_grade
order by loan_grade
--C10 How do income and loan amount jointly affect default rates?
with Finheal as(
select case
			when person_income < 30000 then 'Low income'
			when person_income < 50000 then 'Medium income'
			else 'High income'
		end income_group,
		case
			when loan_amnt <  6500 then 'Low loan amount'
			when loan_amnt < 10000 then 'Medium loan amount'
			else 'High loan amount'
		end loan_amount_group, loan_status
from credit_risk
)
select income_group, loan_amount_group, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from Finheal
group by income_group,loan_amount_group
order by default_percent desc;
--C11 How do interest rate and debt-to-income ratio jointly affect default rates?
with cte as(
	select case
			when loan_int_rate < 10 then 'Low int'
			when loan_int_rate < 18 then 'Medium int'
			else 'High int'
		end int_rate_group,
			case
			when debt_to_income_ratio < 0.2 then 'Low'
			when debt_to_income_ratio < 0.4 then 'Medium'
			else 'High'
		end as debt_income_group, loan_status
from credit_risk 
)
select int_rate_group,debt_income_group,CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from cte
group by int_rate_group,debt_income_group
order by default_percent desc