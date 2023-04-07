-- inpecting  data
select *
from dbo.salesAnalysis

--  checking unique vaules
select distinct status from dbo.salesAnalysis -- nice one to plot
select distinct year_id from dbo.salesAnalysis
select distinct productline from dbo.salesAnalysis
select distinct country from dbo.salesAnalysis -- nice one to plot
select distinct dealsize from dbo.salesAnalysis -- nice one to plot
select distinct territory from dbo.salesAnalysis -- nice to plot

select distinct month_id
from dbo.salesAnalysis
where year_id = 2005

-- anaylsis
-- start by grouping sales by productline
select productline, sum(sales) as revenue
from dbo.salesAnalysis
group by productline
order by 2 desc

select year_id, sum(sales) as revenue
from dbo.salesAnalysis
group by year_id
order by 2 desc

select dealsize, sum(sales)
from dbo.salesAnalysis
group by dealsize
order by 2 desc

-- what was the best month for sales in a spefic year? how much was earned that month

select  month_id, sum(sales) as revenue, count(ordernumber) as frequency
from dbo.salesAnalysis
where year_id = 2004
group by month_id
order by 2 desc

-- november seems to be best month, what product do they sell in november, classic i believe

select  month_id, productline, sum(sales) as revenue, count(productline) as list
from dbo.salesAnalysis
where month_id = 11
and year_id = 2004
group by month_id,productline
order by 3 desc

-- who is our best customer(this could be best answered rfm)
drop table if exists #rfm
;with rfm as (
select
 customername,
 sum(sales) as revenue, avg(sales) as avgrevenue,
 count(ordernumber) as frequency,
 max(orderdate) as lastDate,
 (select max(orderdate) from dbo.salesAnalysis) as maxDate,
 DATEDIFF(dy,max(orderdate),(select max(orderdate) as maxdate from dbo.salesAnalysis)) as recency
 from dbo.salesAnalysis
 group by customername 
 ),

 rfm_calc as (
 select 
 r.*,
 ntile(4) over (order by recency desc ) as rfm_recency,
 ntile(4) over (order by frequency ) as rfm_frequency,
 ntile(4) over (order by revenue ) as rfm_revenue
 from rfm r
 )

 select c.*, rfm_recency + rfm_frequency + rfm_revenue as rfm_cell,
 cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) +  cast(rfm_revenue as varchar) as rfm_cell_String
 into #rfm
 from rfm_calc c

 select customername, rfm_recency, rfm_frequency, rfm_revenue,
 case 
   when rfm_cell_String in (111,112,121,122,123,132,211,212,114,141) then 'lost customers' --lost customers
   when rfm_cell_String in (133,134,143,244,334,343,344) then 'slipping away, cannot lose' -- big spenders who haven't purchased lately
   when rfm_cell_String in (311,411,331) then 'new customers'
   when rfm_cell_String in (222,223,233,322) then 'potential churners'
   when rfm_cell_String in (323,333,321,422,332,432) then 'active' -- customerswho buy often and recently, but at low price
   when rfm_cell_String in (433,434,443,444) then 'loyal'
   end rfm_segement

   from #rfm

-- what products are most often sold together ?

--select * from dbo.salesAnalysiswhere ordernumber = 10411
select distinct ordernumber, stuff(
(select ',' + productcode
from dbo.salesAnalysis as p
where ordernumber in
(
select ordernumber 
from (
select ordernumber, count(*) as rn
from dbo.salesAnalysis
where status = 'shipped'
group by ordernumber
) as m
where rn =2
)
and p.ordernumber = s.ordernumber
for xml path('')),1,1,'') as productcode
from dbo.salesAnalysis s
order by 2 desc




