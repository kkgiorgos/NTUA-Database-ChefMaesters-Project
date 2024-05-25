USE chefmaesters;
	
SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS cuisine;
CREATE TABLE cuisine (
	id int,
	nationality varchar(100) not null,
	image_id int,
	primary key (id),
	foreign key (image_id) references image(id)
);

DROP TABLE IF EXISTS meal_type;
CREATE TABLE meal_type(
	id int,
	title varchar(100) not null,
	primary key (id)
);

DROP TABLE IF EXISTS recipe_meal_type;
CREATE TABLE recipe_meal_type(
	recipe_id int,
	meal_type_id int,
	primary key (recipe_id, meal_type_id),
	foreign key (recipe_id) references recipe(id),
	foreign key (meal_type_id) references meal_type(id)
);

DROP TABLE IF EXISTS meal_tag;
CREATE TABLE meal_tag(
	id int,
	title varchar(100) not null,
	primary key (id)
);


DROP TABLE IF EXISTS recipe_meal_tag;
CREATE TABLE recipe_meal_tag(
	recipe_id int,
	meal_tag_id int,
	primary key (recipe_id, meal_tag_id),
	foreign key (recipe_id) references recipe(id),
	foreign key (meal_tag_id) references meal_tag(id)
);

DROP TABLE IF EXISTS tip;
CREATE TABLE tip(
	id int,
	recipe_id int not null,
	description text not null,
	primary key (id),
	foreign key (recipe_id) references recipe(id)
);

DROP TRIGGER IF EXISTS ins_recipe_tip;
DELIMITER $$
CREATE TRIGGER ins_recipe_tip BEFORE INSERT ON tip FOR EACH ROW
BEGIN 
	IF ((SELECT count(*) FROM tip t WHERE t.recipe_id = new.recipe_id) = 3) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Maximum Tips Allowed is 3!!!';
	END IF;
END$$
DELIMITER ;


DROP TABLE IF EXISTS step;
CREATE TABLE step(
	recipe_id int,
	step_asc_num int,
	description text not null,
	primary key (recipe_id, step_asc_num),
	foreign key (recipe_id) references recipe(id)
);


DROP TABLE IF EXISTS equipment;
CREATE TABLE equipment(
	id int,
	name varchar(100) not null,
	instructions text,
	image_id int,
	primary key (id),
	foreign key (image_id) references image(id)
);

DROP TABLE IF EXISTS recipe_equipment;
CREATE TABLE recipe_equipment(
	recipe_id int,
	equipment_id int,
	primary key (recipe_id, equipment_id),
	foreign key (recipe_id) references recipe(id),
	foreign key (equipment_id) references equipment(id)	
);

DROP TABLE IF EXISTS food_group;
CREATE TABLE food_group(
	id int,
	name varchar(100) not null,
	recipe_classification varchar(100),
	description text,
	image_id int,
	primary key (id),
	foreign key (image_id) references image(id)
);

DROP TABLE IF EXISTS ingredient;
CREATE TABLE ingredient(
	id int,
	title varchar(100) not null,
	calories int,
	fat int,
	protein int,
	carbohydrates int,
	food_group_id int not null,
	image_id int,
	primary key (id),
	foreign key (food_group_id) references food_group(id),
	foreign key (image_id) references image(id)
);

DROP TABLE IF EXISTS quantity_unit;
CREATE TABLE quantity_unit(
	id int,
	name varchar(100) not null,
	conversion_rate decimal(11, 9) not null,
	primary key (id)
);

DROP TABLE IF EXISTS quantity;
CREATE TABLE quantity(
	id int,
	unit_id int,
	amount_specific decimal(6,2),
	amount_unclear varchar(100),
	primary key (id),
	foreign key (unit_id) references quantity_unit(id)
);


DROP TRIGGER IF EXISTS ins_quantity;
DELIMITER $$
CREATE TRIGGER ins_quantity BEFORE INSERT ON quantity FOR EACH ROW
BEGIN 
	IF (new.amount_unclear IS NOT NULL AND (new.amount_specific IS NOT NULL OR new.unit_id IS NOT NULL)) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Amount is unclear, specific should not be defined!!!';
	ELSEIF (new.amount_specific IS NOT NULL AND new.unit_id IS NULL) THEN 
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Specific amount requires unit type!!!';
	ELSEIF (new.unit_id IS NOT NULL AND new.amount_specific IS NULL) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Specific amount unit defined but no amount given!!!';
	ELSEIF (new.amount_unclear IS NULL AND new.amount_specific IS NULL AND new.unit_id IS NULL) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'No quantity defined';
	END IF;
END$$
DELIMITER ;

DROP TABLE IF EXISTS recipe_ingredients;
CREATE TABLE recipe_ingredients (
	recipe_id int,
	ingredient_id int,
	quantity_id int,
	is_primary bool not null,
	primary key (recipe_id, ingredient_id, quantity_id),
	foreign key (recipe_id) references recipe(id),
	foreign key (ingredient_id) references ingredient(id),
	foreign key (quantity_id) references quantity(id)
);

DROP TRIGGER IF EXISTS ins_recipe_ingredient;
DELIMITER $$
CREATE TRIGGER ins_recipe_ingredient BEFORE INSERT ON recipe_ingredients FOR EACH ROW
BEGIN 
	IF (new.is_primary = TRUE AND (SELECT count(*) FROM recipe_ingredients ri WHERE ri.recipe_id = new.recipe_id AND ri.is_primary = TRUE) = 1) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Only one primary ingredient allowed per recipe!!!';
	END IF;
END$$
DELIMITER ;


DROP TABLE IF EXISTS thematic_area;
CREATE TABLE thematic_area(
	id int,
	theme varchar(100) not null,
	description text,
	image_id int,
	primary key (id),
	foreign key (image_id) references image(id)
);


DROP TABLE IF EXISTS recipe_thematic_area;
CREATE TABLE recipe_thematic_area(
	recipe_id int,
	thematic_area_id int,
	primary key (recipe_id, thematic_area_id),
	foreign key (recipe_id) references recipe(id),
	foreign key (thematic_area_id) references thematic_area(id)
);


DROP TABLE IF EXISTS recipe;
CREATE TABLE recipe (
	id int,
	title varchar(100) not null,
	recipe_type enum('Cooking', 'Baking'),
	description text,
	difficulty int,
	cuisine_id int not null,
	output_unit_count int,
	preparation_time time,
	cook_time time,
	image_id int,
	primary key (id),
	constraint difficulty_chk check (difficulty between 1 and 5),
	foreign key (cuisine_id) references cuisine(id),
	foreign key (image_id) references image(id)
);

DROP TABLE IF EXISTS cook_level;
CREATE TABLE cook_level (
	id int,
	level varchar(30) not null,
	primary key (id)
);

DROP TABLE IF EXISTS cook_cuisine;
CREATE TABLE cook_cuisine (
	cuisine_id int,
	cook_id int,
	primary key (cuisine_id, cook_id),
	foreign key (cuisine_id) references cuisine(id),
	foreign key (cook_id) references cook(id)
);


DROP TABLE IF EXISTS cook;
CREATE TABLE cook (
	id int,
	username varchar(32) UNIQUE NOT NULL,	/*This will be indexed automatically*/
	name varchar(100),
	surname varchar(100),
	phone_number varchar(20),
	birth_date date,
	age int,
	experience_years int,
	level_id int not null,
	image_id int,
	primary key (id),
	foreign key (level_id) references cook_level(id),
	foreign key (image_id) references image(id)
);

DROP TABLE IF EXISTS recipe_cook;
CREATE TABLE recipe_cook (
	recipe_id int,
	cook_id int,
	primary key (recipe_id, cook_id),
	foreign key (recipe_id) references recipe(id),
	foreign key (cook_id) references cook(id)
);


DROP TABLE IF EXISTS episode;
CREATE TABLE episode (
	id int auto_increment,
	season_id int not null,
	asc_num int not null,
	image_id int,
	primary key (id),
	foreign key (image_id) references image(id)
);


DROP TABLE IF EXISTS episode_contestants;
CREATE TABLE episode_contestants (
	episode_id int,
	contestant_id int,
	recipe_id int,
	primary key (episode_id, contestant_id),
	foreign key (episode_id) references episode(id),
	foreign key (contestant_id) references cook(id),
	foreign key (recipe_id) references recipe(id)
);

DROP TRIGGER IF EXISTS ins_episode_contestant;
DELIMITER $$
CREATE TRIGGER ins_episode_contestant BEFORE INSERT ON episode_contestants FOR EACH ROW
BEGIN 
	IF ((SELECT count(*) FROM episode_contestants ec WHERE ec.episode_id = new.episode_id) = 10) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Maximum Contestants in Episode Allowed is 10!!!';
	END IF;

	DROP TEMPORARY TABLE IF EXISTS last_three_episodes;
	CREATE TEMPORARY TABLE last_three_episodes
		SELECT e.id
		FROM episode e 
		ORDER BY e.id DESC
		LIMIT 3;

	IF ( (SELECT count(*) 
		FROM episode_contestants ec
		INNER JOIN  last_three_episodes le ON le.id = ec.episode_id
		WHERE ec.contestant_id = new.contestant_id) > 2 ) THEN 
		
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Same contestant cannot appear 3 times in a row!!!';
	END IF;

	IF ( SELECT count(*)
		FROM episode_contestants ec 
		INNER JOIN last_three_episodes le ON le.id = ec.episode_id
		INNER JOIN recipe r ON r.id = recipe_id
		WHERE r.cuisine_id IN 
			(SELECT r.cuisine_id FROM recipe r WHERE r.id = new.recipe_id)
		> 2 ) THEN 
		
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Same cuisine cannot appear 3 times in a row!!!';
	END IF;

	IF ( (SELECT count(*) 
		FROM episode_judges ej 
		WHERE ej.judge_id = new.contestant_id
		AND ej.episode_id = new.episode_id) > 0 ) THEN
	
	SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Contestant cannot appear as judge in the same episode!!!';
	END IF;

	DROP TEMPORARY TABLE IF EXISTS last_three_episodes;
END$$
DELIMITER ;

DROP TABLE IF EXISTS episode_judges;
CREATE TABLE episode_judges (
	episode_id int,
	judge_id int,
	primary key (episode_id, judge_id),
	foreign key (episode_id) references episode(id),
	foreign key (judge_id) references cook(id)
);

DROP TRIGGER IF EXISTS ins_episode_judge;
DELIMITER $$
CREATE TRIGGER ins_episode_judge BEFORE INSERT ON episode_judges FOR EACH ROW
BEGIN
	IF ((SELECT count(*) FROM episode_judges ej WHERE ej.episode_id = new.episode_id) = 3) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Maximum Judges in Episode Allowed is 3!!!';
	END IF;

	DROP TEMPORARY TABLE IF EXISTS last_three_episodes;
	CREATE TEMPORARY TABLE last_three_episodes
		SELECT e.id
		FROM episode e 
		ORDER BY e.id DESC
		LIMIT 3;

	IF ( (SELECT count(*) 
		FROM episode_judges ej 
		INNER JOIN  last_three_episodes le ON le.id = ej.episode_id
		WHERE ej.judge_id = new.judge_id) > 2 ) THEN 
		
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Same judge cannot appear 3 times in a row!!!';
	END IF;

	IF ( (SELECT count(*) 
		FROM episode_contestants ec 
		WHERE ec.contestant_id = new.judge_id 
		AND ec.episode_id = new.episode_id) > 0 ) THEN
	
	SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Judge cannot appear as contestant in the same episode!!!';
	END IF;

	DROP TEMPORARY TABLE IF EXISTS last_three_episodes;
END$$
DELIMITER ;


DROP TABLE IF EXISTS scoring; 
CREATE TABLE scoring (
	episode_id int,
	contestant_id int,
	judge_id int,
	score int not null,
	primary key (episode_id, contestant_id, judge_id),
	foreign key (episode_id) references episode(id),
	foreign key (contestant_id) references cook(id),
	foreign key (judge_id) references cook(id),
	constraint score_chk check (score between 1 and 5)
);

DROP TABLE IF EXISTS image;
CREATE TABLE image (
	id int,
	link text,
	description text,
	primary key (id)
);

DROP PROCEDURE IF EXISTS generate_episode;
DELIMITER $$
CREATE PROCEDURE generate_episode(IN episode_season_id int, IN episode_asc_num int)
BEGIN
	DECLARE episode_id_value INT;
	DECLARE cuisine_id_value INT;
	DECLARE contestant_id_value INT;
	DECLARE recipe_id_value INT;

	-- Cursor is used to iterate through the 10 cuisines
	DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR 
    	SELECT c.id 
		FROM cuisine c
		WHERE c.id NOT IN (
			SELECT r.cuisine_id
			FROM episode_contestants ec 
			INNER JOIN recipe r ON r.id = recipe_id 
			INNER JOIN last_episodes le ON le.id = ec.episode_id
			GROUP BY r.cuisine_id
			HAVING count(r.cuisine_id) > 2
		)
   		ORDER BY RAND() 
   		LIMIT 10;
   	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   	-- This temp table is needed to we don't choose stuff that has appeared 3 times consecutively
	DROP TEMPORARY TABLE IF EXISTS last_episodes;
	CREATE TEMPORARY TABLE last_episodes
		SELECT e.id
		FROM episode e 
		ORDER BY e.id DESC
		LIMIT 3;
	
	-- Create the new episode entry
   	INSERT INTO episode (season_id, asc_num)
    VALUES (episode_season_id, episode_asc_num);
	
   	-- Keep the episode_id of this entry
    SELECT e.id 
   	INTO episode_id_value
   	FROM episode e 
   	WHERE e.season_id = episode_season_id AND e.asc_num = episode_asc_num;
   
    OPEN cur;
    read_loop: LOOP
	    -- Fetch values from the cursor into variables
        FETCH cur INTO cuisine_id_value;
        IF done THEN
        	LEAVE read_loop;
        END IF;
		
       	-- Choose a cook/contestant that belongs to this cuisine
       	SELECT c.id  
       	INTO contestant_id_value
       	FROM cook c
       	INNER JOIN cook_cuisine cc ON cc.cook_id = c.id 
       	WHERE c.id NOT IN ((
       		-- Ensure the contestant has not already been chosen in the episode
       		-- (because a contestant can know many cuisines).
       		SELECT ec.contestant_id 
       		FROM episode_contestants ec 
       		WHERE ec.episode_id = episode_id_value
       	) UNION (
       		-- Ensure the contestant hasn't appeared 3 times in a row
       		SELECT ec.contestant_id 
			FROM episode_contestants ec 
			INNER JOIN last_episodes le ON le.id = ec.episode_id
			GROUP BY ec.contestant_id 
			HAVING count(ec.contestant_id) > 2
       	)) AND cc.cuisine_id = cuisine_id_value
       	ORDER BY RAND()
       	LIMIT 1;
       
       	-- Choose a recipe that the contestant will have to complete.
       	-- This doesn't require a check for the last episodes
       	-- as the constraint is already satisfied by the cuisine choice.
        SELECT r.id
		INTO recipe_id_value
		FROM recipe r 
		WHERE r.cuisine_id = cuisine_id_value
      	ORDER BY RAND()
      	LIMIT 1;
       
      	-- Create the contestant entry
		INSERT INTO episode_contestants (episode_id, contestant_id, recipe_id)
		VALUES (episode_id_value, contestant_id_value, recipe_id_value);
	
		-- Assign the recipe to the cook
		INSERT IGNORE INTO recipe_cook (recipe_id, cook_id)
		VALUES (recipe_id_value, contestant_id_value);
	END LOOP;
    -- Close the cursor
    CLOSE cur;
   
   	-- Choose the 3 judges 
   	-- (we don't care if they appeared as contestants in previous episodes only as judges)
   	INSERT INTO episode_judges (episode_id, judge_id)
	SELECT episode_id_value, c.id
	FROM cook c
	WHERE c.id NOT IN ((
		-- Ensure the judge hasn't appeared 3 times in a row
		SELECT ej.judge_id 
		FROM episode_judges ej 
		INNER JOIN last_episodes le ON le.id = ej.episode_id
		GROUP BY ej.judge_id
		HAVING count(ej.judge_id) > 2
	) UNION (
		-- Ensure the judge hasn't appeared as a contestant in the episode
		SELECT ec.contestant_id
		FROM episode_contestants ec 
		WHERE ec.episode_id = episode_id_value
	)) AND c.id < 20 /* We limit the cooks that can be judges to force good results for some queries */
	ORDER BY RAND()
	LIMIT 3;
	   
	DROP TEMPORARY TABLE IF EXISTS last_episodes;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS generate_episodes;
DELIMITER $$
CREATE PROCEDURE generate_episodes (IN episode_count int)
BEGIN 
	DECLARE season_counter INT;
	DECLARE num INT;
	DECLARE total_insertions INT DEFAULT 0;
	DECLARE random_id INT;
	DECLARE total_episode_count INT;

    SELECT count(*) INTO total_episode_count FROM episode;
   	SET season_counter = (total_episode_count DIV 10) + 1;
   	SET num = total_episode_count % 10 + 1;

    -- We generate episode_count episodes
    WHILE total_insertions < episode_count DO
        CALL generate_episode(season_counter, num);

		-- Progress to the next episode		
        SET num = num + 1;
        SET total_insertions = total_insertions + 1;
		-- Control season rollover
        IF num > 10 THEN
            SET num = 1;
            SET season_counter = season_counter + 1;
        END IF;
    END WHILE;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS fill_episode_scoring;
DELIMITER $$
CREATE PROCEDURE fill_episode_scoring ()
BEGIN 
	INSERT INTO scoring (episode_id, contestant_id, judge_id, score)
	SELECT e.id, ec.contestant_id , ej.judge_id, CEIL(RAND()*5)
	FROM episode e
	INNER JOIN episode_contestants ec ON ec.episode_id = e.id 
	INNER JOIN episode_judges ej ON ej.episode_id = e.id
	WHERE (e.id, ec.contestant_id, ej.judge_id) NOT IN (
		SELECT s.episode_id, s.contestant_id, s.judge_id 
		FROM scoring s
	);
END$$
DELIMITER ;

DROP VIEW IF EXISTS recipe_nutritional_values;
CREATE VIEW recipe_nutritional_values AS
SELECT 
	r.id as recipe_id, 
	sum(q.amount_specific * qu.conversion_rate * i.calories / r.output_unit_count) recipe_calories_per_unit,
	sum(q.amount_specific * qu.conversion_rate * i.fat  / r.output_unit_count) recipe_fat_per_unit,
	sum(q.amount_specific * qu.conversion_rate * i.protein / r.output_unit_count) recipe_protein_per_unit,
	sum(q.amount_specific * qu.conversion_rate * i.carbohydrates / r.output_unit_count) recipe_carbohydrates_per_unit
FROM recipe r 
INNER JOIN recipe_ingredients ri ON r.id = ri.recipe_id 
INNER JOIN ingredient i ON ri.ingredient_id = i.id 
INNER JOIN quantity q ON ri.quantity_id = q.id
INNER JOIN quantity_unit qu ON qu.id = q.unit_id 
GROUP BY r.id;


DROP VIEW IF EXISTS recipe_classification_by_primary_ingredient;
CREATE VIEW recipe_classification_by_primary_ingredient AS
SELECT r.id, r.title, fg.recipe_classification
FROM recipe r
INNER JOIN recipe_ingredients ri ON r.id = ri.recipe_id
INNER JOIN ingredient i ON ri.ingredient_id = i.id
INNER JOIN food_group fg ON i.food_group_id = fg.id
WHERE ri.is_primary = TRUE;

-- Not implemented the handling of draws.
DROP VIEW IF EXISTS winners;
CREATE VIEW winners AS
WITH scores AS (
	SELECT s.episode_id AS ep_id, s.contestant_id AS contestant_id, SUM(s.score) AS tot_score
	FROM scoring s 
	GROUP BY s.episode_id, s.contestant_id 
), max_scores AS (
	SELECT ss.ep_id AS episode_id, MAX(ss.tot_score) AS max_score
	FROM scores ss
	GROUP BY ss.ep_id
) SELECT ms.episode_id, s.contestant_id, ms.max_score
FROM max_scores ms
INNER JOIN scores s ON ms.episode_id = s.ep_id AND ms.max_score = s.tot_score;


CREATE INDEX recipe_title_index ON recipe(title) USING BTREE;
-- DROP INDEX recipe_title_index ON recipe;
CREATE INDEX prep_time_index ON recipe(preparation_time) USING BTREE;
-- DROP INDEX prep_time_index ON recipe;
CREATE INDEX cook_time_index ON recipe(cook_time) USING BTREE;
-- DROP INDEX cook_time_index ON recipe;
CREATE INDEX unit_count_index ON recipe(output_unit_count) USING BTREE;
-- DROP INDEX unit_count_index ON recipe;

CREATE INDEX recipe_id_index ON recipe_ingredients(recipe_id) USING BTREE; 
-- DROP INDEX recipe_id_index ON recipe_ingredients;
CREATE INDEX is_primary_index ON recipe_ingredients(is_primary) USING BTREE;
-- DROP INDEX is_primary_index ON recipe_ingredients;

CREATE INDEX quantity_amount_index ON quantity(amount_specific) USING BTREE; 
-- DROP INDEX quantity_amount_index  ON quantity;

CREATE INDEX cook_names_index ON cook(name, surname) USING BTREE;
-- DROP INDEX cook_names_index ON cook;
CREATE INDEX cook_age_index ON cook(age) USING BTREE; 
-- DROP INDEX cook_age_index  ON cook;
CREATE INDEX cook_exp_years_index ON cook(experience_years) USING BTREE; 
-- DROP INDEX cook_exp_years_index  ON cook;

CREATE INDEX season_index ON episode(season_id) USING BTREE; 
-- DROP INDEX season_index ON episode;
CREATE INDEX score_index ON scoring(score) USING BTREE;
-- DROP INDEX score_index ON scoring;

DROP VIEW IF EXISTS cook_user_info_vw;
CREATE VIEW cook_user_info_vw AS
SELECT c.*
FROM cook c 
WHERE c.username = SUBSTRING_INDEX(USER(), '@', 1);

DROP VIEW IF EXISTS cook_user_episode_view;
CREATE VIEW cook_user_episode_view AS
SELECT e.*
FROM episode e
INNER JOIN episode_contestants ec ON ec.episode_id = e.id
INNER JOIN cook_user_info_vw c ON c.id = ec.contestant_id;

DROP VIEW IF EXISTS cook_user_episode_contestants_view;
CREATE VIEW cook_user_episode_contestants_view AS
SELECT ec.*
FROM episode_contestants ec 
WHERE ec.episode_id IN (SELECT e.id FROM cook_user_episode_view e);

DROP VIEW IF EXISTS cook_user_episode_judges_view;
CREATE VIEW cook_user_episode_judges_view AS
SELECT ej.*
FROM episode_judges ej 
WHERE ej.episode_id IN (SELECT e.id FROM cook_user_episode_view e);

DROP VIEW IF EXISTS cook_user_scoring_view;
CREATE VIEW cook_user_scoring_view AS
SELECT s.*
FROM scoring s 
WHERE s.episode_id IN (SELECT e.id FROM cook_user_episode_view e);

DROP VIEW IF EXISTS cook_user_recipe_vw;
CREATE VIEW cook_user_recipe_vw AS
SELECT r.*
FROM recipe r 
INNER JOIN recipe_cook rc ON rc.recipe_id = r.id 
INNER JOIN cook_user_info_vw cuiv ON rc.cook_id = cuiv.id;

DROP TRIGGER IF EXISTS ins_recipe;
DELIMITER $$
CREATE TRIGGER ins_recipe AFTER INSERT ON recipe FOR EACH ROW
BEGIN 
	INSERT INTO recipe_cook (recipe_id, cook_id)
		SELECT new.id, cuiv.id
		FROM cook_user_info_vw cuiv
		LIMIT 1;
END$$
DELIMITER ;

DROP VIEW IF EXISTS cook_user_tip_vw;
CREATE VIEW cook_user_tip_vw AS
SELECT t.*
FROM tip t 
INNER JOIN cook_user_recipe_vw curv ON t.recipe_id = curv.id;

DROP VIEW IF EXISTS cook_user_step_vw;
CREATE VIEW cook_user_step_vw AS
SELECT s.*
FROM step s  
INNER JOIN cook_user_recipe_vw curv ON s.recipe_id = curv.id;

DROP VIEW IF EXISTS cook_user_recipe_meal_tag_vw;
CREATE VIEW cook_user_recipe_meal_tag_vw AS
SELECT rmt.*
FROM recipe_meal_tag rmt  
INNER JOIN cook_user_recipe_vw curv ON rmt.recipe_id = curv.id;

DROP VIEW IF EXISTS cook_user_recipe_ingredients_vw;
CREATE VIEW cook_user_recipe_ingredients_vw AS
SELECT ri.*
FROM recipe_ingredients ri  
INNER JOIN cook_user_recipe_vw curv ON ri.recipe_id = curv.id;

DROP VIEW IF EXISTS cook_user_quantity_vw;
CREATE VIEW cook_user_quantity_vw AS
SELECT q.*
FROM quantity q 
INNER JOIN recipe_ingredients ri ON ri.ingredient_id = q.id
INNER JOIN cook_user_recipe_vw curv ON ri.recipe_id = curv.id;

DROP VIEW IF EXISTS cook_user_recipe_equipment_vw;
CREATE VIEW cook_user_recipe_equipment_vw AS
SELECT re.*
FROM recipe_equipment re  
INNER JOIN cook_user_recipe_vw curv ON re.recipe_id = curv.id;

DROP VIEW IF EXISTS cook_user_recipe_thematic_area_vw;
CREATE VIEW cook_user_recipe_thematic_area_vw AS
SELECT rta.*
FROM recipe_thematic_area rta  
INNER JOIN cook_user_recipe_vw curv ON rta.recipe_id = curv.id;

DROP VIEW IF EXISTS cook_user_recipe_meal_type_vw;
CREATE VIEW cook_user_recipe_meal_type_vw AS
SELECT rmt.*
FROM recipe_meal_type rmt  
INNER JOIN cook_user_recipe_vw curv ON rmt.recipe_id = curv.id;

DROP VIEW IF EXISTS cook_user_cook_cuisine_vw;
CREATE VIEW cook_user_cook_cuisine_vw AS
SELECT cc.*
FROM cook_cuisine cc
INNER JOIN cook_user_info_vw cuiv ON cuiv.id = cc.cook_id; 

CREATE ROLE IF NOT EXISTS chefmaesters_admin_user, chefmaesters_cook_user;
GRANT ALL PRIVILEGES ON chefmaesters.* TO chefmaesters_admin_user;
 
GRANT SELECT ON chefmaesters.quantity_unit TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.food_group TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.meal_tag TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.meal_type TO chefmaesters_cook_user;
GRANT SELECT, INSERT ON chefmaesters.equipment TO chefmaesters_cook_user;
GRANT SELECT, INSERT ON chefmaesters.ingredient TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.cuisine TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.cook_level TO chefmaesters_cook_user;

GRANT SELECT, UPDATE ON chefmaesters.cook_user_info_vw TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.cook_user_episode_view TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.cook_user_episode_contestants_view TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.cook_user_episode_judges_view TO chefmaesters_cook_user;
GRANT SELECT ON chefmaesters.cook_user_scoring_view TO chefmaesters_cook_user;

GRANT SELECT, UPDATE ON cook_user_recipe_vw TO chefmaesters_cook_user;
GRANT INSERT ON recipe TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_tip_vw TO chefmaesters_cook_user;
GRANT INSERT ON tip TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_step_vw TO chefmaesters_cook_user;
GRANT INSERT ON step TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_recipe_meal_tag_vw TO chefmaesters_cook_user;
GRANT INSERT ON recipe_meal_tag TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_recipe_ingredients_vw TO chefmaesters_cook_user;
GRANT INSERT ON recipe_ingredients TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_quantity_vw TO chefmaesters_cook_user;
GRANT INSERT ON quantity TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_recipe_equipment_vw TO chefmaesters_cook_user;
GRANT INSERT ON equipment TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_recipe_thematic_area_vw TO chefmaesters_cook_user;
GRANT INSERT ON recipe_thematic_area TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_recipe_meal_type_vw TO chefmaesters_cook_user;
GRANT INSERT ON recipe_meal_type TO chefmaesters_cook_user;
GRANT SELECT, UPDATE ON cook_user_cook_cuisine_vw TO chefmaesters_cook_user;
GRANT INSERT ON cook_cuisine TO chefmaesters_cook_user;

SET FOREIGN_KEY_CHECKS=1;
