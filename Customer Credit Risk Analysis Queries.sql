USE Project
select*
from credit_risk
--C1 Các mục đích vay cụ thể (giáo dục, y tế, cá nhân, hợp nhất nợ) có mang lại rủi ro cao hơn không?
select loan_intent, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
group by loan_intent;
--C2 Loại hình việc làm và việc sở hữu nhà có tạo ra sự khác biệt không?
select person_home_ownership,employment_type, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
group by person_home_ownership,employment_type
order by default_percent desc;
--C3 Tỷ lệ khoản vay trên thu nhập và tỷ lệ nợ trên thu nhập liên quan như thế nào đến việc hoàn trả?
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
--C4 Xếp hạng khoản vay (loan grades) hoặc điều khoản nào có vẻ an toàn hơn, và loại nào rủi ro hơn?
select loan_grade, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
group by loan_grade
order by default_percent desc;
--C5 Có sự khác biệt rõ rệt nào giữa những người vay ở Mỹ, Anh và Canada không?
select country, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
group by country
order by default_percent desc;
--C6 Lịch sử nợ quá hạn trong quá khứ hoặc lịch sử tín dụng dài hạn ảnh hưởng thế nào đến kết quả khoản vay?
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
--C7 Có bao nhiêu khách hàng được xếp vào Hạng khoản vay A,B hoặc C (an toàn, lãi suất thấp) nhưng lại có Lịch sử vỡ nợ trong quá khứ? Tỷ lệ vỡ nợ thực tế của nhóm này là bao nhiêu?
select cb_person_default_on_file, loan_grade, count(*) number_of_default, CAST(ROUND(100.0 * SUM(loan_status) / COUNT(loan_status), 2) AS DECIMAL(5,2)) default_percent
from credit_risk
where loan_grade in ('A','B','C') and cb_person_default_on_file = 'Y'
group by cb_person_default_on_file, loan_grade
order by default_percent
--C8 Gánh nặng nợ nần (DTI) kết hợp với Trạng thái nhà ở tác động kép đến rủi ro vỡ nợ ra sao?
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
--C9 Mức chênh lệch lãi suất trung bình giữa nhóm vỡ nợ và không vỡ nợ là bao nhiêu bên trong cùng một Hạng khoản vay (Loan Grade)?
select loan_grade, 
		round(avg(case when loan_status = 1 then loan_int_rate end),2) avg_int_default, 
		round(avg(case when loan_status = 0 then loan_int_rate end),2) avg_int_non_default, 
		round(avg(case when loan_status = 1 then loan_int_rate end) - avg(case when loan_status = 0 then loan_int_rate end),2) rate_diff  
from credit_risk
group by loan_grade
order by loan_grade
--C10 Sự tác động giữa thu nhập và khoản vay đến tỉ lệ vỡ nợ
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
--C11 Sự tác động giữa lãi suất và tỉ lệ nợ trên thu nhập đến tỉ lệ vỡ nợ
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