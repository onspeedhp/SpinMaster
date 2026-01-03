-- Vibrant Theme: Blue, Red, Purple, Yellow
-- Using CTE to assign colors based on row order since ID is UUID
WITH RankedRewards AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as rn
  FROM rewards_config
)
UPDATE rewards_config
SET color_hex = CASE
  WHEN (r.rn % 4) = 1 THEN '#29B6F6' -- Light Blue
  WHEN (r.rn % 4) = 2 THEN '#EF5350' -- Red
  WHEN (r.rn % 4) = 3 THEN '#AB47BC' -- Purple
  ELSE '#FFCA28' -- Yellow
END
FROM RankedRewards r
WHERE rewards_config.id = r.id;
