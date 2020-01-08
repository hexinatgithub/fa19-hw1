DROP VIEW IF EXISTS q0, q1i, q1ii, q1iii, q1iv, q2i, q2ii, q2iii, q3i, q3ii, q3iii, q4i, q4ii, q4iii, q4iv, q4v;

-- Question 0
CREATE VIEW q0(era) 
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM People
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM People
  WHERE namefirst ~ '.* .*'
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, NULLIF(AVG(height), 0), COUNT(*)
  FROM People
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT *
  FROM q1iii
  WHERE avgheight > 70
  ORDER BY birthyear;
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT 
    p.namefirst, p.namelast, p.playerid, h.yearid
  FROM 
    People as p 
  INNER JOIN 
    HallofFame as h ON p.playerid = h.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid DESC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT 
    p.namefirst, p.namelast, p.playerid, c.schoolid, p.yearid
  FROM 
    q2i as p 
  INNER JOIN 
    CollegePlaying as c ON p.playerid = C.playerid
  INNER JOIN
    Schools as s ON c.schoolid = s.schoolid
  WHERE
    s.schoolstate = 'CA'
  ORDER BY p.yearid DESC, s.schoolid ASC, p.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT 
    p.playerid, p.namefirst, p.namelast, c.schoolid
  FROM 
    q2i as p 
  LEFT JOIN 
    CollegePlaying as c ON p.playerid = c.playerid
  ORDER BY playerid DESC, schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  WITH annualSlg AS (
    SELECT playerid, yearid,
      ((h - (h2b + h3b + hr) + 2.0 * h2b + 3.0 * h3b + 4.0 * hr) / ab)::FLOAT AS slg
    FROM Batting
    WHERE ab > 50
  )
  SELECT p.playerid, p.namefirst, p.namelast, a.yearid, a.slg
  FROM people AS p, annualSlg AS a
  WHERE p.playerid = a.playerid
  ORDER BY a.slg DESC, a.yearid, a.playerid
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  WITH lifeSlg AS (
    SELECT ((SUM(h) - (SUM(h2b) + SUM(h3b) + SUM(hr)) + 2.0 * SUM(h2b)
      + 3.0 * SUM(h3b) + 4.0 * SUM(hr)) / SUM(ab))::FLOAT AS slg, playerid
    FROM Batting
    GROUP BY playerid
    HAVING SUM(ab) > 50
  )
  SELECT p.playerid, p.namefirst, p.namelast, l.slg
  FROM people AS p, lifeSlg AS l
  WHERE p.playerid = l.playerid
  ORDER BY l.slg DESC, l.playerid
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  WITH lifeSlg AS (
    SELECT ((SUM(h) - (SUM(h2b) + SUM(h3b) + SUM(hr)) + 2.0 * SUM(h2b)
      + 3.0 * SUM(h3b) + 4.0 * SUM(hr)) / SUM(ab))::FLOAT AS slg, playerid
    FROM Batting
    GROUP BY playerid
    HAVING SUM(ab) > 50
  )
  SELECT p.namefirst, p.namelast, l.slg
  FROM lifeSlg AS l, people AS p
  WHERE l.playerid = p.playerid
    AND l.slg >
    (SELECT l2.slg FROM lifeSlg AS l2 WHERE l2.playerid = 'mayswi01')
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg, stddev)
AS
  SELECT 
    yearid, MIN(salary), MAX(salary), AVG(salary), STDDEV(salary)
  FROM
    salaries
  GROUP BY
    yearid
  ORDER BY
    yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH min_max(min, max, diff) AS (
    SELECT 
      MIN(salary) AS min, MAX(salary) AS max,
      ((MAX(salary) - MIN(salary)) / 10)::INTEGER AS diff
    FROM
      salaries
    WHERE
      yearid = 2016
  ), rawbucket(bucket) AS (
    SELECT
      width_bucket(salary, min_max.min, min_max.max, 10)
    FROM 
      salaries, min_max
    WHERE 
      yearid = 2016
  ), histogram(binid) AS (
    SELECT CASE WHEN bucket <= 10 THEN bucket - 1
                ELSE 9
           END
    FROM 
      rawbucket
  ), histwrange(binid, low, high) AS (
    SELECT binid,
      min + diff * binid AS low,
      min + diff * (binid + 1) AS high
    FROM
      histogram, min_max
  )
  SELECT 
    binid, low, high, COUNT(*)
  FROM 
    histwrange
  GROUP BY 
    binid, low, high
  ORDER BY 
    binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH yearly AS (
    SELECT 
      yearid, MIN(salary) AS min, MAX(salary) AS max, AVG(salary) AS avg
    FROM 
      salaries
    GROUP BY 
      yearid
  ), yearDiff AS (
    SELECT 
      yearid, min - (lag(min) OVER (ORDER BY yearid)) AS mindiff,
      max - (lag(max) OVER (ORDER BY yearid)) AS maxdiff,
      avg - (lag(avg) OVER (ORDER BY yearid)) AS avgdiff
    FROM 
      yearly
  )
  SELECT 
    * 
  FROM
    yearDiff WHERE yearid > (SELECT MIN(yearid) FROM yearDiff)
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT 
    p.playerid, p.namefirst, p.namelast, s.salary, s.yearid
  FROM 
    people AS p, salaries AS s
  WHERE 
    p.playerid = s.playerid
    AND ((s.salary =
      (SELECT MAX(s2.salary) FROM salaries AS s2 WHERE yearid = 2000)
      AND s.yearid = 2000)
    OR (s.salary =
      (SELECT MAX(s3.salary) FROM salaries AS s3 WHERE yearid = 2001)
      AND s.yearid = 2001))
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT 
    a.teamid, MAX(s.salary) - MIN(s.salary) AS diffAvg
  FROM 
    allstarfull AS a, salaries AS s
  WHERE
    a.yearid = 2016 AND s.yearid = 2016 AND a.playerid = s.playerid
  GROUP BY 
    a.teamid
  ORDER BY 
    a.teamid
;

