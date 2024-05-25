-- 3.15. Ποιες ομάδες τροφίμων δεν έχουν εμφανιστεί ποτέ στον διαγωνισμό;
SELECT fg.*
FROM food_group fg
WHERE fg.id NOT IN (
	SELECT DISTINCT fg.id
	FROM episode_contestants ec  
	INNER JOIN recipe_ingredients ri ON ec.recipe_id = ri.recipe_id 
	INNER JOIN ingredient i ON ri.ingredient_id = i.id 
	INNER JOIN food_group fg ON i.food_group_id = fg.id
);


-- 3.14. Ποια θεματική ενότητα έχει εμφανιστεί τις περισσότερες φορές στο διαγωνισμό;
SELECT ta.*, count(ta.id) as appearances
FROM episode_contestants ec 
INNER JOIN recipe_thematic_area rta ON rta.recipe_id = ec.recipe_id 
INNER JOIN thematic_area ta ON rta.thematic_area_id = ta.id 
GROUP BY ta.id
ORDER BY count(ta.id) DESC
LIMIT 1;


-- 3.13. Ποιο επεισόδιο συγκέντρωσε τον χαμηλότερο βαθμό επαγγελματικής κατάρτισης 
-- (κριτές και μάγειρες);
SELECT e2.*, tjl.total_judge_level+tcl.total_contestant_level as total_level
FROM 
(
	SELECT e.id as id, sum(cl.id) as total_judge_level
	FROM episode_judges ej 
	INNER JOIN cook c ON ej.judge_id = c.id 
	INNER JOIN cook_level cl ON c.level_id = cl.id
	INNER JOIN episode e ON e.id = ej.episode_id 
	GROUP BY e.id
) AS tjl,
(
	SELECT e.id as id, sum(cl.id) as total_contestant_level
	FROM episode_contestants ec 
	INNER JOIN cook c ON ec.contestant_id = c.id 
	INNER JOIN cook_level cl ON c.level_id = cl.id
	INNER JOIN episode e ON e.id = ec.episode_id 
	GROUP BY e.id
) AS tcl
INNER JOIN episode e2 ON tcl.id = e2.id
WHERE tcl.id = tjl.id
ORDER BY total_level ASC
LIMIT 1;


-- 3.12. Ποιο ήταν το πιο τεχνικά δύσκολο, από πλευράς συνταγών, 
-- επεισόδιο του διαγωνισμού ανά έτος;
WITH total_episode_difficulty AS (
	SELECT e.*, sum(r.difficulty) as total_difficulty
	FROM episode e 
	INNER JOIN episode_contestants ec ON e.id = ec.episode_id 
	INNER JOIN recipe r ON r.id = ec.recipe_id 
	GROUP BY e.id
)
SELECT ted2.*
FROM (
	SELECT ted.season_id AS id, max(ted.total_difficulty) AS total_difficulty
	FROM total_episode_difficulty ted
	GROUP BY ted.season_id
) AS max_season_difficulties
INNER JOIN total_episode_difficulty ted2 ON 
	ted2.season_id = max_season_difficulties.id AND 
	max_season_difficulties.total_difficulty = ted2.total_difficulty;


-- 3.11. Βρείτε τους top-5 κριτές που έχουν δώσει συνολικά 
-- την υψηλότερη βαθμολόγηση σε ένα μάγειρα. 
-- (όνομα κριτή, όνομα μάγειρα και συνολικό σκορ βαθμολόγησης)

-- In case of same score we choose the smaller ids
SELECT 
	(CONCAT(cc.name, ' ', cc.surname)) as contestant_full_name, 
	(CONCAT(cj.name, ' ', cj.surname)) as judge_full_name, 
	sum(s.score) as total_score
FROM scoring s
INNER JOIN cook cc ON cc.id = s.contestant_id
INNER JOIN cook cj ON cj.id = s.judge_id
GROUP BY s.contestant_id, s.judge_id
ORDER BY total_score DESC, s.contestant_id, s.judge_id ASC
LIMIT 5;


-- 3.10. Ποιες Εθνικές κουζίνες έχουν τον ίδιο αριθμό συμμετοχών σε διαγωνισμούς, 
-- σε διάστημα δύο συνεχόμενων ετών, με τουλάχιστον 3 συμμετοχές ετησίως
-- Assume the seasons are not necessarily identical
WITH total_valid_appearances AS (
	WITH valid_appearances AS (
		SELECT 
			e.season_id AS season_id, 
			c.id AS cuisine_id, 
			count(c.id) AS yearly_appearances
		FROM episode_contestants ec 
		INNER JOIN recipe r ON ec.recipe_id = r.id 
		INNER JOIN cuisine c ON c.id = r.cuisine_id 
		INNER JOIN episode e ON ec.episode_id = e.id 
		GROUP BY e.season_id, c.id 
		HAVING yearly_appearances > 3
	)
	SELECT va1.cuisine_id AS cuisine_id, va1.season_id AS season_id, (va1.yearly_appearances + va2.yearly_appearances) AS total_appearances
	FROM valid_appearances va1
	INNER JOIN valid_appearances va2 ON va1.cuisine_id = va2.cuisine_id
	WHERE va1.season_id = va2.season_id - 1
)
SELECT tva1.cuisine_id, tva1.season_id, tva2.cuisine_id, tva2.season_id, tva1.total_appearances
FROM total_valid_appearances tva1
INNER JOIN total_valid_appearances tva2 ON tva1.total_appearances = tva2.total_appearances AND tva1.cuisine_id < tva2.cuisine_id
ORDER BY total_appearances DESC;
-- Assume the seasons must be the same
WITH total_valid_appearances AS (
	WITH valid_appearances AS (
		SELECT 
			e.season_id AS season_id, 
			c.id AS cuisine_id, 
			count(c.id) AS yearly_appearances
		FROM episode_contestants ec 
		INNER JOIN recipe r ON ec.recipe_id = r.id 
		INNER JOIN cuisine c ON c.id = r.cuisine_id 
		INNER JOIN episode e ON ec.episode_id = e.id 
		GROUP BY e.season_id, c.id 
		HAVING yearly_appearances > 3
	)
	SELECT va1.cuisine_id AS cuisine_id, va1.season_id AS season_id, (va1.yearly_appearances + va2.yearly_appearances) AS total_appearances
	FROM valid_appearances va1
	INNER JOIN valid_appearances va2 ON va1.cuisine_id = va2.cuisine_id
	WHERE va1.season_id = va2.season_id - 1
)
SELECT tva1.cuisine_id, tva2.cuisine_id, tva1.total_appearances
FROM total_valid_appearances tva1
INNER JOIN total_valid_appearances tva2 ON tva1.total_appearances = tva2.total_appearances AND tva1.season_id = tva2.season_id AND tva1.cuisine_id < tva2.cuisine_id
ORDER BY total_appearances DESC;
-- Assume that we are looking for the cuisines that had the same number of appearances two years in a row
WITH valid_appearances AS (
	SELECT 
		e.season_id AS season_id, 
		c.id AS cuisine_id, 
		count(c.id) AS yearly_appearances
	FROM episode_contestants ec 
	INNER JOIN recipe r ON ec.recipe_id = r.id 
	INNER JOIN cuisine c ON c.id = r.cuisine_id 
	INNER JOIN episode e ON ec.episode_id = e.id 
	GROUP BY e.season_id, c.id 
	HAVING yearly_appearances > 3
)
SELECT va1.cuisine_id, va1.season_id AS from_season, va2.season_id AS to_season, va1.yearly_appearances AS common_appearances
FROM valid_appearances va1
INNER JOIN valid_appearances va2 ON va1.yearly_appearances = va2.yearly_appearances AND va1.cuisine_id = va2.cuisine_id
WHERE va1.season_id = va2.season_id - 1
ORDER BY common_appearances DESC;


-- 3.9. Λίστα με μέσο όρο αριθμού γραμμάριων υδατανθράκων στο διαγωνισμό ανά έτος;
-- We assume that the carbohydrate gram count is the recipe_carbohydrates_per_unit
SELECT season_id, AVG(rnv.recipe_carbohydrates_per_unit) AS average_carbohydrates_per_season
FROM episode_contestants ec 
INNER JOIN recipe_nutritional_values rnv ON ec.recipe_id = rnv.recipe_id
INNER JOIN episode e ON ec.episode_id = e.id
GROUP BY e.season_id;


-- 3.8. Σε ποιο επεισόδιο χρησιμοποιήθηκαν τα περισσότερα εξαρτήματα (εξοπλισμός); Ομοίως με
-- ερώτημα 3.6, η απάντηση σας θα πρέπει να περιλαμβάνει εκτός από το ερώτημα (query),
-- εναλλακτικό Query Plan (πχ με force index), τα αντίστοιχα traces και τα συμπεράσματα σας από
-- την μελέτη αυτών.
SELECT r.id AS id, r.title AS recipe_title, COUNT(re.equipment_id) AS equipment_count
FROM recipe_equipment re
INNER JOIN recipe r ON r.id = re.recipe_id
GROUP BY r.id
ORDER BY equipment_count DESC
LIMIT 1;


EXPLAIN SELECT r.id AS id, r.title AS recipe_title, COUNT(re.equipment_id) AS equipment_count
FROM recipe_equipment re
INNER JOIN recipe r ON r.id = re.recipe_id
GROUP BY r.id
ORDER BY equipment_count DESC
LIMIT 1;

EXPLAIN SELECT r.id AS id, r.title AS recipe_title, COUNT(re.equipment_id) AS equipment_count
FROM recipe_equipment re
USE INDEX ()
INNER JOIN recipe r 
USE INDEX ()
ON r.id = re.recipe_id
GROUP BY r.id
ORDER BY equipment_count DESC
LIMIT 1;

-- 3.7. Βρείτε όλους τους μάγειρες που συμμετείχαν τουλάχιστον 
-- 5 λιγότερες φορές από τον μάγειρα με τις περισσότερες συμμετοχές σε επεισόδια.
WITH contestant_appearance_counts AS (
	SELECT ec.contestant_id AS contestant_id, count(ec.contestant_id) AS contestant_appearances
	FROM episode_contestants ec 
	GROUP BY ec.contestant_id
)
SELECT cac.contestant_id, cac.contestant_appearances
FROM contestant_appearance_counts cac
WHERE cac.contestant_appearances >= (SELECT MAX(contestant_appearances) FROM contestant_appearance_counts) - 5
ORDER BY cac.contestant_appearances DESC;

-- 3.6. Πολλές συνταγές καλύπτουν περισσότερες από μια ετικέτες. Ανάμεσα σε ζεύγη πεδίων (π.χ.
-- brunch και κρύο πιάτο) που είναι κοινά στις συνταγές, βρείτε τα 3 κορυφαία (top-3) ζεύγη που
-- εμφανίστηκαν σε επεισόδια. Για το ερώτημα αυτό η απάντηση σας θα πρέπει να περιλαμβάνει
-- εκτός από το ερώτημα (query), εναλλακτικό Query Plan (πχ με force index), τα αντίστοιχα traces
-- και τα συμπεράσματα σας από την μελέτη αυτών.
WITH recipe_tags_joined AS
(
    SELECT r.id AS recipe_id, mt.id AS tag_id, mt.title AS tag_title
    FROM recipe_meal_tag rmt
    INNER JOIN recipe r ON rmt.recipe_id = r.id
    INNER JOIN meal_tag mt ON mt.id = rmt.meal_tag_id
)
SELECT rtj1.tag_title AS tag1, rtj2.tag_title AS tag2, COUNT(rtj1.tag_id) AS appearances
FROM recipe_tags_joined rtj1
INNER JOIN recipe_tags_joined rtj2 ON rtj1.recipe_id = rtj2.recipe_id AND rtj1.tag_id < rtj2.tag_id
GROUP BY rtj1.tag_id, rtj2.tag_id
ORDER BY appearances DESC
LIMIT 3;


EXPLAIN WITH recipe_tags_joined AS
(
    SELECT r.id AS recipe_id, mt.id AS tag_id, mt.title AS tag_title
    FROM recipe_meal_tag rmt
    INNER JOIN recipe r ON rmt.recipe_id = r.id
    INNER JOIN meal_tag mt ON mt.id = rmt.meal_tag_id
)
SELECT rtj1.tag_title AS tag1, rtj2.tag_title AS tag2, COUNT(rtj1.tag_id) AS appearances
FROM recipe_tags_joined rtj1
INNER JOIN recipe_tags_joined rtj2 ON rtj1.recipe_id = rtj2.recipe_id AND rtj1.tag_id < rtj2.tag_id
GROUP BY rtj1.tag_id, rtj2.tag_id
ORDER BY appearances DESC
LIMIT 3;

WITH recipe_tags_joined AS
(
    SELECT r.id AS recipe_id, mt.id AS tag_id, mt.title AS tag_title
    FROM recipe_meal_tag rmt
    STRAIGHT_JOIN recipe r ON rmt.recipe_id = r.id
    STRAIGHT_JOIN meal_tag mt ON mt.id = rmt.meal_tag_id
)
SELECT rtj1.tag_title AS tag1, rtj2.tag_title AS tag2, COUNT(rtj1.tag_id) AS appearances
FROM recipe_tags_joined rtj1
INNER JOIN recipe_tags_joined rtj2 ON rtj1.recipe_id = rtj2.recipe_id AND rtj1.tag_id < rtj2.tag_id
GROUP BY rtj1.tag_id, rtj2.tag_id
ORDER BY appearances DESC
LIMIT 3;


EXPLAIN WITH recipe_tags_joined AS
(
    SELECT r.id AS recipe_id, mt.id AS tag_id, mt.title AS tag_title
    FROM recipe_meal_tag rmt
    STRAIGHT_JOIN recipe r ON rmt.recipe_id = r.id
    STRAIGHT_JOIN meal_tag mt ON mt.id = rmt.meal_tag_id
)
SELECT rtj1.tag_title AS tag1, rtj2.tag_title AS tag2, COUNT(rtj1.tag_id) AS appearances
FROM recipe_tags_joined rtj1
INNER JOIN recipe_tags_joined rtj2 ON rtj1.recipe_id = rtj2.recipe_id AND rtj1.tag_id < rtj2.tag_id
GROUP BY rtj1.tag_id, rtj2.tag_id
ORDER BY appearances DESC
LIMIT 3;

-- 3.5. Ποιοι κριτές έχουν συμμετάσχει στον ίδιο αριθμό επεισοδίων 
-- σε διάστημα ενός έτους με περισσότερες από 3 εμφανίσεις;
-- This version assumes we are looking for judge pairs with the same amount of episode appearances within the same season
WITH episode_counts AS (
    SELECT ej.judge_id, e.season_id, COUNT(ej.episode_id) AS episode_count
    FROM episode_judges ej
    JOIN episode e ON ej.episode_id = e.id
    GROUP BY ej.judge_id, e.season_id
    HAVING COUNT(ej.episode_id) > 3
)
SELECT a.judge_id AS judge1_id, b.judge_id AS judge2_id, a.episode_count
FROM episode_counts a
JOIN episode_counts b ON a.season_id = b.season_id AND a.episode_count = b.episode_count AND a.judge_id < b.judge_id
ORDER BY a.episode_count DESC;
-- This version assumes we are looking for judge pairs with the same amount of episode appearances in any two seasons (not necessarily the same)
WITH episode_counts AS (
    SELECT ej.judge_id, e.season_id, COUNT(ej.episode_id) AS episode_count
    FROM episode_judges ej
    JOIN episode e ON ej.episode_id = e.id
    GROUP BY ej.judge_id, e.season_id
    HAVING COUNT(ej.episode_id) > 3
)
SELECT a.judge_id AS judge1_id, b.judge_id AS judge2_id, a.episode_count
FROM episode_counts a
JOIN episode_counts b ON a.episode_count = b.episode_count AND a.judge_id < b.judge_id
ORDER BY a.episode_count DESC;


-- 3.4. Βρείτε τους μάγειρες που δεν έχουν συμμετάσχει ποτέ σε 
-- ως κριτές σε κάποιο επεισόδιο.
SELECT c.id, c.name, c.surname
FROM cook c
LEFT JOIN episode_judges ej ON c.id = ej.judge_id
GROUP BY c.id
HAVING COUNT(ej.judge_id) = 0;

-- 3.3. Βρείτε τους νέους μάγειρες (ηλικία < 30 ετών) 
-- που έχουν τις περισσότερες συνταγές.
SELECT c.id, c.name, c.surname, c.age, count(rc.recipe_id) as recipe_count
FROM cook c 
INNER JOIN recipe_cook rc ON c.id = rc.cook_id
WHERE c.age < 30
GROUP BY c.id
ORDER BY recipe_count DESC;

-- 3.2. Για δεδομένη Εθνική κουζίνα και έτος, ποιοι μάγειρες ανήκουν 
-- σε αυτήν και ποιοι μάγειρες συμμετείχαν σε επεισόδια;
-- Find the cooks that know the specific natonal cuisine
SELECT 
    c.id AS cook_id,
    c.name AS cook_name,
    c.surname AS cook_surname
FROM cook AS c
JOIN cook_cuisine AS cc ON c.id = cc.cook_id
WHERE cc.cuisine_id = :cuisine_id; 
-- Find the cooks that participated in a given season's episodes
SELECT
    c.id AS cook_id,
    c.name AS cook_name,
    c.surname AS cook_surname
FROM cook AS c
JOIN episode_contestants AS ec ON c.id = ec.contestant_id
JOIN episode AS e ON ec.episode_id = e.id
WHERE e.season_id = :season_id;
-- Find the cooks that participated in a given season's episodes under a specific cuisine
SELECT 
    c.id AS cook_id,
    c.name AS cook_name,
    c.surname AS cook_surname
FROM cook AS c
JOIN cook_cuisine AS cc ON c.id = cc.cook_id
JOIN episode_contestants AS ec ON c.id = ec.contestant_id
JOIN episode AS e ON ec.episode_id = e.id
WHERE cc.cuisine_id= :cuisine_id AND e.season_id= :season_id;
    
-- 3.1. Μέσος Όρος Αξιολογήσεων (σκορ) ανά μάγειρα και Εθνική κουζίνα.
SELECT 
	c.id AS cook_id,
    CONCAT(c.name, ' ', c.surname) AS cook_name,
    AVG(s.score) AS average_rating_cook
FROM scoring AS s
JOIN episode_contestants AS ec ON s.episode_id = ec.episode_id AND s.contestant_id = ec.contestant_id
JOIN cook AS c ON ec.contestant_id = c.id
GROUP BY c.id
ORDER BY c.name, c.surname;


SELECT 
    cu.id AS cuisine_id,
    cu.nationality AS national_cuisine,
    AVG(s.score) AS average_rating_cuisine
FROM scoring AS s
JOIN episode_contestants AS ec ON s.episode_id = ec.episode_id AND s.contestant_id = ec.contestant_id
JOIN cook AS c ON ec.contestant_id=c.id
JOIN cook_cuisine AS cc ON c.id=cc.cook_id 
JOIN cuisine AS cu ON cc.cuisine_id = cu.id
GROUP BY cu.id
ORDER BY cu.nationality;