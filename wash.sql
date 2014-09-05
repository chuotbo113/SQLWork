#  List all the actors who acted in at least
# one film in 2nd half of the 19th century and
# in at least one film in the 1st half of the 20th century.
SELECT DISTINCT a.fname, a.lname
	FROM Actor a, Movie m1, Movie m2, Cast c1, Cast c2
	WHERE c1.pid = a.id
	AND c1.mid = m1.id
	AND m1.year BETWEEN 1850 AND 1900
	AND c2.pid = a.id
	AND c2.mid = m2.id
	AND m2.year BETWEEN 1901 AND 1950;

# List all the directors who directed a film in a leap year
SELECT DISTINCT a.id, fname, lname
	FROM Directors a, Movie_Directors b, Movie c 
	WHERE a.id = b.did
	AND b.mid = c.id
	AND ((c.year % 4 = 0 and c.year % 100 <> 0)
	OR c.year % 400 = 0);

#  List all the movies that have the same year as the movie 'Shrek (2001)',
# but a better rank. (Note: bigger value of rank implies a better rank)
SELECT * FROM Movie
	WHERE year = 2001
	AND rank > (
		SELECT rank
		FROM Movie
		WHERE name = 'Shrek (2001)');

#  List first name and last name of all the actors
# who played in the movie 'Officer 444 (1926)'accessible
SELECT fname, lname, year, name
	FROM Actor a, Movie b, Cast c
	WHERE a.id = c.pid
	AND b.id = c.mid
	AND b.name = 'Officer 444 (1926)';

# List all directors in descending order of the number of films they directed
SELECT a.id, a.fname, a.lname, count(b.mid) AS num_movies
	FROM Directors a LEFT OUTER JOIN Movie_Directors b
	ON a.id = b.did
	GROUP BY a.id, a.fname, a.lname
	ORDER BY num_movies DESC;

#  Find the film(s) with the largest cast.
SELECT m.name, COUNT(*)
	AS cast_size
	FROM Movie m
	INNER JOIN Cast c
	ON m.id = c.mid
	GROUP BY m.id, m.name
	HAVING COUNT(*) >= ALL (SELECT COUNT(*)
							FROM Cast
							GROUP BY mid);
# Cast size 1304

# Find the film(s) with the smallest cast.
CREATE TEMPORARY TABLE smallest AS (SELECT COUNT(c.pid)
									FROM Movie AS m LEFT OUTER JOIN Cast AS c
									ON m.id = c.mid GROUP BY m.id);

SELECT m.name, COUNT(c.pid) AS cast_size
	FROM Movie AS m LEFT OUTER JOIN Cast AS c
	ON m.id = c.mid
	GROUP BY m.id, m.name
	HAVING COUNT(c.pid) <= ALL(SELECT * FROM smallest);
# Cast size 0

# Find all the actors who acted in films by at least 10 distinct directors
# (i.e. actors who worked with at least 10 distinct directors).accessible
DROP TABLE IF EXISTS actcast;
CREATE TEMPORARY TABLE actcast AS(
	SELECT id, fname, lname, gender, pid, mid
	AS movieid, role
	FROM Actor a
	INNER JOIN Cast c
	ON a.id = c.pid);

CREATE INDEX id_index ON actcast(id);
CREATE INDEX mid_index ON actcast(movieid);

CREATE TEMPORARY TABLE actcastdirect AS (
	SELECT * FROM actcast a
	INNER JOIN Movie_Directors md
	ON a.movieid = md.mid);

CREATE INDEX id_index ON actcastdirect(id);
CREATE INDEX mid_index ON actcastdirect(movieid);
CREATE INDEX did_index ON actcastdirect(did);

SELECT id, fname, lname, count(DISTINCT did) AS num
	FROM actcastdirect
	GROUP BY id, fname, lname
	HAVING count(DISTINCT did) >= 10;

# Find all actors who acted only in films before 1960.
DROP TABLE IF EXISTS actcast;

CREATE TEMPORARY TABLE actcast AS (
	SELECT a.id, a.fname, a.lname, c.mid
	FROM Actor a INNER JOIN Cast c
	ON a.id = c.pid);

CREATE INDEX id_index ON actcast(id);
CREATE INDEX mid_index ON actcast(mid);

SELECT * FROM actcastmovie LIMIT 10;

CREATE TEMPORARY TABLE actcastmovie AS (
	SELECT a.id, fname, lname, year
	FROM actcast a
	INNER JOIN Movie m
	ON a.mid = m.id);

CREATE INDEX id_index ON actcastmovie(id);

SELECT id, fname, lname FROM actcastmovie
	GROUP BY id, fname, lname
	HAVING max(year) < 1960;

# Find the films with more women actors than men.
DROP TABLE IF EXISTS moviecast;
DROP TABLE IF EXISTS moviecastactor;

CREATE TEMPORARY TABLE moviecast AS (
	SELECT id, name, year, pid
	FROM Movie m
	INNER JOIN Cast c
	ON m.id = c.mid);

CREATE INDEX id_index ON moviecast(id);

CREATE TEMPORARY TABLE moviecastactor AS (
	SELECT a.id as aid, m.id as mid, name, year, fname, lname, gender FROM moviecast m
	INNER JOIN Actor a
	ON m.pid = a.id);

CREATE INDEX aid_index ON moviecastactor(aid);
CREATE INDEX mid_index ON moviecastactor(mid);

SELECT * FROM moviecastactor LIMIT 1;
SELECT count(*) FROM moviecastactor WHERE gender = 'M';

SELECT mid, name
	FROM moviecastactor
	WHERE gender = 'F'
	GROUP BY mid, name
	HAVING count(*) > 2390395;
###################################
SELECT m.id, m.name
FROM Movie AS m, Cast AS c1, Actor AS a
WHERE c1.mid = m.id AND c1.pid = a.id AND a.gender = 'F'
GROUP BY m.id, m.name
HAVING count(*) > (SELECT count(*)
                   FROM Cast AS c2, Actor AS a
                   WHERE c2.mid = m.id AND c2.pid = a.id AND a.gender = 'M');

# For every pair of male and female actors that appear together in some film,
# find the total number of films in which they appear together.
# Sort the answers in decreasing order of the total number of films.

SELECT MaleAct.fname, MaleAct.lname, FemAct.fname, FemAct.lname, count(*) AS num_films
FROM Actor AS MaleAct
    INNER JOIN Cast AS MaleCast ON MaleAct.id = MaleCast.pid
    INNER JOIN Cast AS FemCast ON MaleCast.mid = FemCast.mid
    INNER JOIN Actor AS FemAct ON FemAct.id = FemCast.pid
WHERE
      MaleAct.gender = 'M' AND
      FemAct.gender = 'F'
GROUP BY MaleAct.id, FemAct.id, MaleAct.fname, MaleAct.lname, FemAct.fname, FemAct.lname
HAVING num_films > 0
ORDER BY num_films DESC;



#  For every actor, list the films he/she appeared in their debut year.
# Sort the results by last name of the actor.
DROP TABLE IF EXISTS actorcast;
DROP TABLE IF EXISTS actorcastmovie;

CREATE TEMPORARY TABLE actorcast AS (
	SELECT id AS aid, fname, lname, gender, role, mid
	FROM Actor a
	INNER JOIN Cast c
	ON a.id = c.pid);

CREATE INDEX aid_index ON actorcast(aid);
CREATE INDEX mid_index ON actorcast(mid);

CREATE TEMPORARY TABLE actorcastmovie AS (
	SELECT aid, fname, lname, name, year
	FROM actorcast a
	INNER JOIN Movie m
	ON a.mid = m.id);

CREATE INDEX aid_index ON actorcastmovie(aid);
CREATE INDEX mid_index ON actorcastmovie(mid);

SELECT fname, lname, name, year
FROM actorcastmovie AS a
WHERE year = (SELECT MIN(year)
                FROM Movie AS m1, Cast AS c1
                WHERE m1.id = c1.mid AND c1.pid = a.aid);

#############################################
SELECT a.fname, a.lname, m.name, year
FROM Actor AS a, Movie AS m, Cast AS c
WHERE a.id = c.pid AND
      m.id = c.mid AND
      m.year = (SELECT MIN(year)
                FROM Movie AS m1, Cast AS c1
                WHERE m1.id = c1.mid AND c1.pid = a.id)
ORDER BY a.lname;

# The Bacon number of an actor is the length of the shortest path
# between the actor and Kevin Bacon in the "co-acting" graph.
# That is, Kevin Bacon has Bacon number 0; all actors who acted in the same film as KB
# have Bacon number 1; all actors who acted in the same film as some actor with Bacon
# number 1 have Bacon number 2, etc. Return all actors whose Bacon number is 2.

SELECT count(DISTINCT pid) FROM Cast WHERE mid IN (
    SELECT mid FROM Cast WHERE pid IN (
        SELECT DISTINCT pid FROM Cast WHERE mid IN (
            SELECT mid FROM Cast INNER JOIN Actor
			ON pid = Actor.id WHERE fname='Kevin' AND lname='Bacon')))
AND pid NOT IN
    (SELECT DISTINCT pid FROM Cast WHERE mid IN (
        SELECT mid FROM Cast INNER JOIN Actor ON pid=Actor.id WHERE fname='Kevin' AND lname='Bacon'));
