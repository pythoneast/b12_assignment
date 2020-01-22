/* 
    First problem
    Queries for MySQL DB
*/

/* create a new database */
CREATE DATABASE b12 CHARACTER SET utf8 COLLATE utf8_general_ci;

/* use database b12 */
USE b12;

/* create a table 'users' */
CREATE TABLE users (
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`email` VARCHAR(255) NOT NULL,
	`name` VARCHAR(255) NOT NULL,
	`source` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE INDEX `users_emails_idx` (`email` ASC)
) ENGINE=InnoDB;

/* create a table 'businesses' */
CREATE TABLE businesses (
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`id_users` INT UNSIGNED NOT NULL,
	`name` VARCHAR(255) NOT NULL,
	`industry` VARCHAR(255) NOT NULL,
	`monthly_plan` VARCHAR(255),
	PRIMARY KEY (`id`),
	INDEX `fk_businesses_1_idx` (`id_users` ASC),
	CONSTRAINT `fk_businesses_1`
	FOREIGN KEY (`id_users`)
	REFERENCES `users` (`id`)
) ENGINE=InnoDB;

/* add rows into the table 'users' */
INSERT INTO users 
(id, email, name, source)
VALUES 
(NULL, 'john@gmail.com', 'john', 'facebook'),
(NULL, 'dan@gmail.com', 'Dan', 'blog'),
(NULL, 'bill@gmail.com', 'Bill', 'instagram');

/* add rows into a table 'businesses' */
INSERT INTO businesses 
(id, id_users, name, industry, monthly_plan)
VALUES 
(NULL, 1, 'Coca-Cola', 'Drinks', 'starter'),
(NULL, 2, 'Liverpool FC', 'Sport', 'professional'),
(NULL, 3, 'Solar City', 'Energy', NULL);

/* calculate paid conversion rate */
SELECT source AS marketing_channel, 
CONCAT((COUNT(*)*100/(SELECT count(*) FROM `users`)) ,  " %") AS paid_conversion_rate 
FROM users
JOIN businesses 
WHERE users.id = businesses.id_users 
AND businesses.monthly_plan IS NOT NULL
GROUP BY source;

/* create a user without any related business object */
INSERT INTO users 
(id, email, name, source)
VALUES 
(NULL, 'ann@gmail.com', 'Ann', 'facebook');

/* correct query for calculating paid conversion rate for new conditions */
SELECT source AS marketing_channel, CONCAT((COUNT(*)*100/(SELECT COUNT(*) FROM `users` JOIN businesses WHERE users.id = businesses.id_users)) ,  " %") 
AS paid_conversion_rate FROM users
JOIN businesses 
WHERE users.id = businesses.id_users 
AND businesses.monthly_plan IS NOT NULL
GROUP BY source;

/*
	To handle these requirements we need to create many-to-many relationship
	between users and businesses tables. To do this we must create
	an intermediate table users_businesses that mainly stores the primary keys
	of each relationship. There will be 3 fields in users_businesses table: id
	for relationship object, id_users for user id and
	id_businesses for business id. Also we need to set id_users and
	id_businesses as foreign keys to link users and businesses tables together.
	As for conversion analysis, if we use every relationship between two tables
	we will count business subscription for every user associated with business
	object. Instead of 1 real business subscription we will get, for example,
	2 subscriptions, it will give us wrong paid conversion rate. It would be
	more correct to calculate the paid conversion rate not for each user but
	for each business instead. It will give us more reliable and precise data.
*/

/* Queries for SQLITE3 DB */

/* create a table 'users' */
CREATE TABLE users (
	`id` INTEGER NOT NULL,
	`email` TEXT NOT NULL,
	`name` TEXT NOT NULL,
	`source` TEXT NOT NULL,
	PRIMARY KEY (`id`)
);

/* create an index for email field in table 'users' */
CREATE UNIQUE INDEX `users_emails_idx` 
ON `users` (`email` ASC);

/* create a table 'businesses' */
CREATE TABLE businesses (
	`id` INTEGER NOT NULL,
	`id_users` INTEGER NOT NULL,
	`name` TEXT NOT NULL,
	`industry` TEXT NOT NULL,
	`monthly_plan` TEXT,
	PRIMARY KEY (`id`),
	CONSTRAINT `fk_businesses_1`
	FOREIGN KEY (`id_users`)
	REFERENCES `users` (`id`)
);

/* create an index for id_users field in table 'businesses' */
CREATE INDEX `fk_businesses_1_idx` 
ON `businesses` (`id_users` ASC);

/* add rows in tables 'users' */
INSERT INTO users 
(id, email, name, source)
VALUES 
(NULL, 'john@gmail.com', 'john', 'facebook'),
(NULL, 'dan@gmail.com', 'Dan', 'blog'),
(NULL, 'bill@gmail.com', 'Bill', 'instagram');

/* add rows in tables 'businesses' */
INSERT INTO businesses 
(id, id_users, name, industry, monthly_plan)
VALUES 
(NULL, 1, 'Coca-Cola', 'Drinks', 'starter'),
(NULL, 2, 'Liverpool FC', 'Sport', 'professional'),
(NULL, 3, 'Solar City', 'Energy', NULL);

/* calculate paid conversion rate */
SELECT source AS marketing_channel, 
(COUNT(*)*100/(SELECT count(*) FROM `users`)) AS paid_conversion_rate 
FROM users
JOIN businesses 
WHERE users.id = businesses.id_users 
AND businesses.monthly_plan IS NOT NULL
GROUP BY source;

/* create a new user without any related business */
INSERT INTO users 
(id, email, name, source)
VALUES 
(NULL, 'ann@gmail.com', 'Ann', 'facebook');

/* correct query for calculating paid conversion rate for new conditions */
SELECT source AS marketing_channel,
(COUNT(*)*100/(SELECT COUNT(*) FROM `users` JOIN businesses
WHERE users.id = businesses.id_users))
AS paid_conversion_rate FROM users
JOIN businesses 
WHERE users.id = businesses.id_users 
AND businesses.monthly_plan IS NOT NULL
GROUP BY source;

/*
	To handle these requirements we need to create many-to-many relationship
	between users and businesses tables. To do this we must create
	an intermediate table users_businesses that mainly stores the primary keys
	of each relationship. There will be 3 fields in users_businesses table: id
	for relationship object, id_users for user id and
	id_businesses for business id. Also we need to set id_users and
	id_businesses as foreign keys to link users and businesses tables together.
	As for conversion analysis, if we use every relationship between two tables
	we will count business subscription for every user associated with business
	object. Instead of 1 real business subscription we will get, for example,
	2 subscriptions, it will give us wrong paid conversion rate. It would be
	more correct to calculate the paid conversion rate not for each user but
	for each business instead. It will give us more reliable and precise data.
*/
