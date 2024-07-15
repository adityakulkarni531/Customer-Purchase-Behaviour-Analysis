-- Database
use sql_projects;

-- Inspecting Data 
select * from [dbo].[automobile_sales_data];

-- Checking Unique Values
select distinct STATUS from [dbo].[automobile_sales_data] -- plot
select distinct YEAR_ID from [dbo].[automobile_sales_data]
select distinct PRODUCTLINE from [dbo].[automobile_sales_data] -- plot
select distinct COUNTRY from [dbo].[automobile_sales_data] -- plot
select distinct DEALSIZE from [dbo].[automobile_sales_data] -- plot
select distinct TERRITORY from [dbo].[automobile_sales_data] -- plot

select distinct MONTH_ID
from dbo.automobile_sales_data
where YEAR_ID = 2005 -- only 5 months

-- Analysis

-- grouping sales by productline

select PRODUCTLINE, sum(SALES) as Revenue
from [dbo].[automobile_sales_data]
group by PRODUCTLINE
order by 2 desc

select YEAR_ID, sum(SALES) as Revenue
from [dbo].[automobile_sales_data]
group by YEAR_ID
order by 2 desc

select DEALSIZE, sum(SALES) as Revenue
from [dbo].[automobile_sales_data]
group by DEALSIZE
order by 2 desc


-- what was the best month fro sales in a specific year? how much was earned that month?

select MONTH_ID, sum(SALES) as Revenue, count(ORDERNUMBER) as Frequency
from [dbo].[automobile_sales_data]
where YEAR_ID = 2005 -- change year to see the rest
group by MONTH_ID
order by 2 desc


-- November seems to be the best month, what product do they sell in november?

select MONTH_ID, PRODUCTLINE, sum(SALES) as Revenue, count(ORDERNUMBER) as Frequency
from [dbo].[automobile_sales_data]
where YEAR_ID = 2004 and MONTH_ID = 11 -- change year to see the rest
group by MONTH_ID, PRODUCTLINE
order by 3 desc


-- who is the best customer (with RFM technique)

drop table if exists #rfm
;with rfm as 
(
	select
		CUSTOMERNAME,
		sum(SALES) as MonetaryValue,
		avg(SALES) as AvgMonetaryValue,
		count(ORDERLINENUMBER) as Frequency,
		max(ORDERDATE) AS last_order_date,
		(select max(ORDERDATE) 
		from [dbo].[automobile_sales_data]) as max_order_date,
		datediff(DD, max(ORDERDATE), (select max(ORDERDATE)
										from [dbo].[automobile_sales_data])) as Recency

	from [dbo].[automobile_sales_data]
	group by CUSTOMERNAME

),
rfm_calc as
(
	
	select r.*,
		ntile(4) over (order by Recency desc) as rfm_recency,
		ntile(4) over (order by Frequency) as rfm_frequency,
		ntile(4) over (order by MonetaryValue) as rfm_monetary
	from rfm as r

)
select c.*,
		rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
		cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as rfm_cell_string
into #rfm
from rfm_calc as c;

select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	case
		when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost_customers'
		when rfm_cell_string in (133,134,143,234,244,334,343,344,144) then 'slipping away, cannot lose'
		when rfm_cell_string in (311,411,331,421) then 'new_customers'
		when rfm_cell_string in (222,223,233,322) then 'potential churners'
		when rfm_cell_string in (323,333,321,422,332,432,423) then 'active'
		when rfm_cell_string in (433,434,443,444) then 'loyal'
	end as rfm_segment
from #rfm

-- Mini Gifts Distributions Ltd. and Euro Shopping channel are these tw0 best customers



-- What Products are most often sold together?


select distinct ORDERNUMBER, stuff(
	(select ',' + PRODUCTCODE
	from [dbo].[automobile_sales_data] as p
	where ORDERNUMBER in 
			(
			select ORDERNUMBER -- two products sold together or only two items ordered
			from (
				select ORDERNUMBER, count(*) as rn
				from [dbo].[automobile_sales_data]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
				) as m
			where rn = 2 -- number of products sold together
			)
			and p.ORDERNUMBER = s.ORDERNUMBER
			for xml path ('')), 1, 1, '')

from [dbo].[automobile_sales_data] as s
order by 2 desc


