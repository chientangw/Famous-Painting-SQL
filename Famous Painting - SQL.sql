--=============================
--      Artworks Table       --
--=============================
SELECT TOP (1000) [work_id]
      ,[name]
      ,[artist_id]
      ,[style]
      ,[museum_id]
  FROM [master].[dbo].[fp_work]

--==========================
--      Artist Table      --
--==========================
SELECT TOP (1000) [artist_id]
      ,[full_name]
      ,[first_name]
      ,[middle_names]
      ,[last_name]
      ,[nationality]
      ,[style]
      ,[birth]
      ,[death]
  FROM [master].[dbo].[fp_artist]

--===================================
--      Artwork Subject Table      --
--===================================
  SELECT TOP (1000) [work_id]
      ,[subject]
  FROM [master].[dbo].[fp_subject]  

--================================
--      Picture Size Table      --
--================================
  SELECT [work_id]
      ,[size_id]
      ,[sale_price]
      ,[regular_price]
  FROM [master].[dbo].[fp_product_size]


--===============================
--      Canvas Size Table      --
--===============================
SELECT TOP (1000) [size_id]
      ,[width]
      ,[height]
      ,[label]
  FROM [master].[dbo].[fp_canvas_size]

--=================================================
--      Image Link Table (Links Not Working)     --
--=================================================
-- SELECT TOP (1000) [work_id]
--       ,[url]
--       ,[thumbnail_small_url]
--       ,[thumbnail_large_url]
--   FROM [master].[dbo].[fp_image_link]

--==========================
--      Museum Table      --
--==========================
SELECT TOP (1000) [museum_id]
      ,[name]
      ,[address]
      ,[city]
      ,[state]
      ,[postal]
      ,[country]
      ,[phone]
      ,[url]
  FROM [master].[dbo].[fp_museum]

--================================
--      Museum Hours Table      --
--================================
SELECT TOP (1000) [museum_id]
      ,[day]
      ,[open]
      ,[close]
  FROM [master].[dbo].[fp_museum_hours]

DROP TABLE IF EXISTS #museum_schedule
SELECT  mh.[museum_id]
    ,   m.[name]        AS museum_name
    ,   m.[country]     AS museum_country
    ,   MAX(CASE WHEN [day] = 'Sunday'      THEN CAST([open] AS VARCHAR(20)) + ' to ' + CAST([close] AS VARCHAR(20)) ELSE Null END)    AS sun_schedule
    ,   MAX(CASE WHEN [day] = 'Monday'      THEN CAST([open] AS VARCHAR(20)) + ' to ' + CAST([close] AS VARCHAR(20)) ELSE Null END)    AS mon_schedule
    ,   MAX(CASE WHEN [day] = 'Tuesday'     THEN CAST([open] AS VARCHAR(20)) + ' to ' + CAST([close] AS VARCHAR(20)) ELSE Null END)    AS tue_schedule
    ,   MAX(CASE WHEN [day] = 'Wednesday'   THEN CAST([open] AS VARCHAR(20)) + ' to ' + CAST([close] AS VARCHAR(20)) ELSE Null END)    AS wed_schedule
    ,   MAX(CASE WHEN [day] = 'Thursday'    THEN CAST([open] AS VARCHAR(20)) + ' to ' + CAST([close] AS VARCHAR(20)) ELSE Null END)    AS thu_schedule
    ,   MAX(CASE WHEN [day] = 'Friday'      THEN CAST([open] AS VARCHAR(20)) + ' to ' + CAST([close] AS VARCHAR(20)) ELSE Null END)    AS fri_schedule
    ,   MAX(CASE WHEN [day] = 'Saturday'    THEN CAST([open] AS VARCHAR(20)) + ' to ' + CAST([close] AS VARCHAR(20)) ELSE Null END)    AS sat_schedule
    ,   m.[url]         AS museum_url
INTO    #museum_schedule        
FROM    [master].[dbo].[fp_museum_hours] mh 
        LEFT JOIN [master].[dbo].[fp_museum] m
            ON mh.[museum_id] = m.[museum_id]
GROUP BY mh.[museum_id], m.[name], m.[country], m.[url] 
--select * from #museum_schedule

UPDATE  A
SET     sun_schedule = COALESCE(sun_schedule,'Closed')
    ,   mon_schedule = COALESCE(mon_schedule,'Closed')
    ,   tue_schedule = COALESCE(tue_schedule,'Closed')
    ,   wed_schedule = COALESCE(wed_schedule,'Closed')
    ,   thu_schedule = COALESCE(thu_schedule,'Closed')
    ,   fri_schedule = COALESCE(fri_schedule,'Closed')
    ,   sat_schedule = COALESCE(sat_schedule,'Closed')
FROM    #museum_schedule A
--select * from #museum_schedule

--============================================
--              AGGREGATIONS                --
--============================================
--           ART WORK DETAIL                --
--============================================
DROP TABLE IF EXISTS #artwork_detail_master
SELECT  w.[work_id]         AS [work_id]     
    ,   w.[name]            AS [work_name] 
    ,   ws.[subject]        AS [work_subject]
    ,   w.[style]           AS [work_style]    
    ,   w.[artist_id]       AS [artist_id]
    ,   a.[full_name]       AS [artist_full_name]
    ,   a.[nationality]     AS [artist_nationality]

    ,   w.[museum_id]       
    ,   mh.[museum_name]    
    ,   mh.[museum_country] 
    ,   mh.[museum_url]     
    -- ,   mh.[sun_schedule]   
    -- ,   mh.[mon_schedule]
    -- ,   mh.[tue_schedule]
    -- ,   mh.[wed_schedule]
    -- ,   mh.[thu_schedule]
    -- ,   mh.[fri_schedule]
    -- ,   mh.[sat_schedule]
INTO    #artwork_detail_master
FROM    [master].[dbo].[fp_work] w
        LEFT JOIN [master].[dbo].[fp_subject] ws 
            ON w.[work_id] = ws.[work_id]
        LEFT JOIN #museum_schedule mh 
            ON w.[museum_id] = mh.[museum_id]      
        LEFT JOIN [master].[dbo].[fp_artist] a 
            ON w.[artist_id] = a.[artist_id]
ORDER BY w.[artist_id]
--select * from #artwork_detail_master order by artist_id



--========================================
--          MUSEUM ARTWORK COUNT        --
--========================================
DROP TABLE IF EXISTS #artwork_vol_rank_by_museum
SELECT  m.[name]                AS museum_name 
    ,   m.[country]             AS museum_country
    ,   a.[full_name]           AS artist_full_name
    ,   COUNT(w.[work_id])      AS work_vol
    ,   SUM(ps.[regular_price]) AS total_value
    ,   ROW_NUMBER() OVER(PARTITION BY m.[name] ORDER BY COUNT(w.[work_id]) DESC, MAX(ps.[regular_price]) DESC ) AS vol_rank
INTO    #artwork_vol_rank_by_museum
FROM    [master].[dbo].[fp_museum] m 
        LEFT JOIN [master].[dbo].[fp_work] w
            ON m.[museum_id] = w.[museum_id]
        LEFT JOIN [master].[dbo].[fp_artist] a 
            ON w.[artist_id] = a.[artist_id]
        LEFT JOIN [master].[dbo].[fp_product_size] ps 
            ON w.[work_id] = ps.[work_id]
GROUP BY  m.[name], m.[country], a.[full_name]
--select * from #artwork_vol_rank_by_museum

DROP TABLE IF EXISTS #top5_artwork_by_museum
SELECT  museum_name, museum_country
    ,   SUM(work_vol)                                               AS total_vol
    ,   MAX(CASE WHEN vol_rank = 1 THEN artist_full_name    END)    AS top_1_artist
    ,   MAX(CASE WHEN vol_rank = 1 THEN work_vol            END)    AS top_1_vol    
    ,   MAX(CASE WHEN vol_rank = 2 THEN artist_full_name    END)    AS top_2_artist
    ,   MAX(CASE WHEN vol_rank = 2 THEN work_vol            END)    AS top_2_vol  
    ,   MAX(CASE WHEN vol_rank = 3 THEN artist_full_name    END)    AS top_3_artist
    ,   MAX(CASE WHEN vol_rank = 3 THEN work_vol            END)    AS top_3_vol  
    ,   MAX(CASE WHEN vol_rank = 4 THEN artist_full_name    END)    AS top_4_artist
    ,   MAX(CASE WHEN vol_rank = 4 THEN work_vol            END)    AS top_4_vol  
    ,   MAX(CASE WHEN vol_rank = 5 THEN artist_full_name    END)    AS top_5_artist  
    ,   MAX(CASE WHEN vol_rank = 5 THEN work_vol            END)    AS top_5_vol                    
INTO    #top5_artwork_by_museum
FROM    #artwork_vol_rank_by_museum
--WHERE   vol_rank <= 5
GROUP BY museum_name, museum_country
ORDER BY museum_country, SUM(work_vol) DESC
--select * from #top5_artwork_by_museum order by museum_country, total_vol desc

select * from #top5_artwork_by_museum
select * from #artwork_vol_rank_by_museum where museum_name = 'Museum of Fine Arts of Nancy'
select * from [master].[dbo].[fp_museum] where [name] = 'Museum of Fine Arts of Nancy'
select * from [master].[dbo].[fp_work] where museum_id = 64