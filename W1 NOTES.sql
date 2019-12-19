#query basics
#https://cloud.google.com/bigquery/docs/reference/standard-sql/
SELECT column
FROM   `project.dataset.table` #e.g. bigquery-public-data.irrs_990.irs_990_2015

SELECT FORMAT("%'d", torevenue) #45105 -> 45,105 更好读
                                #但是标题的torevenue也会被改
                                #-> SELECT FORMAT(...) as revenue

SELECT torevenue AS revenue,
    ein,
    operateschools170cd AS is_school
FROM 
    `bigquery-public-data.irrs_990.irs_990_2015`
WHERE operateschools170cd = 'Y' #why not use is_school='Y'??? 因为在这个时候alias is not known at that filtering time
ORDER BY torevenue DESC
LIMIT 10
avoid using * 不然啥都会show

SELECT
    SUM(torevenue) AS total_2015_revenue,
    ROUND(AVG(torevenue), 2) AS  avg_revenue, #round解决了小数点过多的问题 弄到2位小数

#对于aggregated & unaggregated 的东东 记得加Group BY
SELECT 
    company,
    SUM(revenue) AS total
FROM table
GROUP BY company

SELECT
    ein,   
    tax_pd,
    PARSE_DATE("%Y%m", CAST(tax_pd AS STRING)) AS tax_period
FROM `bigquery-public-data.irrs_990.irs_990_2015`
WHERE
    EXTRACT(YEAR FROM
        PARSE_DATE('%Y%m', CAST(tax_pd AS STRING))) = 2014
LIMIT 10


#DATA types, Date functions and NULLs
CAST("12345" AS INT64)
CAST("2018-08-01" AS DATE)
CAST("apple" AS INT64)  -> NULL


#Wildcard Filters with LIKE
SELECT 
    ein,
    name
FROM
    `bigquery-public-data.irrs_990.irs_990_ein`
WHERE
    LOWER(name) LIKE 'help%' #begin with help 类似*
LIMIT 10;

WA的lab
#standardSQL
SELECT
fullVisitorId
FROM `data-to-insights.ecommerce.rev_transactions`

Without aggregations, limits, or sorting, this query is not insightful
check
The page title is missing from the columns in SELECT

但没有missing column alias / LIMIT

#standardSQL
    #how many visitors reached hits_page_pageTitle = 'Checkout Confirmation'
SELECT
COUNT(fullVisitorId) AS visitor_count
, hits_page_pageTitle
FROM `data-to-insights.ecommerce.rev_transactions`
WHERE hits_page_pageTitle = "Checkout Confirmation" #为了避免大小写敏感 可以考虑改成 LOWER(hits_page_pageTitle) = "Checkout Confirmation"
GROUP BY hits_page_pageTitle #如果只count 没有deduplicate 正确的方法是用group by


#standardSQL
    #geoNetwork_city with the most total transactions
SELECT
geoNetwork_city,
SUM(totals_transactions) AS total_products_ordered,
COUNT( DISTINCT fullVisitorId) AS distinct_visitors,
SUM(totals_transactions) / COUNT( DISTINCT fullVisitorId) AS avg_products_ordered
#这里注意 很容易错误的把total_products_ordered 错误的当成了人均product_ordered 
FROM
`data-to-insights.ecommerce.rev_transactions`
#WHERE avg_products_ordered > 20  You cannot filter aggregated fields & alias fields in the `WHERE` clause (use `HAVING` instead)
HAVING avg_products_ordered > 20 
GROUP BY geoNetwork_city
ORDER BY avg_products_ordered DESC

#standardSQL
    #number of products in each hits_product_v2ProductCategory

#no aggregate functions & Large GROUP BYs really hurt performance (consider filtering first and/or using aggregation functions)
SELECT hits_product_v2ProductName, hits_product_v2ProductCategory
FROM `data-to-insights.ecommerce.rev_transactions`
GROUP BY 1,2 #这里就是意思是group by 第一列&第二列  运行起来确实超级慢


#Correct
SELECT
COUNT(DISTINCT hits_product_v2ProductName) as number_of_products, #和人的distinct不要忘 不然就不是不同的了
hits_product_v2ProductCategory
FROM `data-to-insights.ecommerce.rev_transactions`
WHERE hits_product_v2ProductName IS NOT NULL
GROUP BY hits_product_v2ProductCategory #先group by 1个 再order另一个 好很多
ORDER BY number_of_products DESC
LIMIT 5
 
    