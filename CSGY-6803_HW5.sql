/*
	Kyle Timmermans
	Principles of DB Systems
	HW5
	11/26/2022
	PostgreSQL 15
*/

-- Schema
DROP TABLE IF EXISTS Parents_Children;
DROP TABLE IF EXISTS Persons;

CREATE TABLE Persons (
  name VARCHAR(64) PRIMARY KEY,
  gender CHAR(1) NOT NULL
);

CREATE TABLE Parents_Children (
  parent VARCHAR(64),
  child VARCHAR(64),
  PRIMARY KEY (parent, child),
  FOREIGN KEY (parent) REFERENCES Persons(name),
  FOREIGN KEY (child) REFERENCES Persons(name)
);

INSERT INTO Persons (name, gender) VALUES ('Ann', 'F');
INSERT INTO Persons (name, gender) VALUES ('Bob', 'M');
INSERT INTO Persons (name, gender) VALUES ('Cory', 'M');
INSERT INTO Persons (name, gender) VALUES ('Dave', 'M');
INSERT INTO Persons (name, gender) VALUES ('Emma', 'F');
INSERT INTO Persons (name, gender) VALUES ('Fred', 'M');
INSERT INTO Persons (name, gender) VALUES ('Gab', 'Q');
INSERT INTO Persons (name, gender) VALUES ('Hil', 'F');
INSERT INTO Persons (name, gender) VALUES ('Ian', 'M');

INSERT INTO Parents_Children (parent, child) VALUES ('Ann', 'Bob');
INSERT INTO Parents_Children (parent, child) VALUES ('Ann', 'Cory');
INSERT INTO Parents_Children (parent, child) VALUES ('Bob', 'Dave');
INSERT INTO Parents_Children (parent, child) VALUES ('Bob', 'Emma');
INSERT INTO Parents_Children (parent, child) VALUES ('Cory', 'Fred');
INSERT INTO Parents_Children (parent, child) VALUES ('Cory', 'Gab');
INSERT INTO Parents_Children (parent, child) VALUES ('Ian', 'Bob');
INSERT INTO Parents_Children (parent, child) VALUES ('Hil', 'Gab');


-- Queries 

/* 1A - Siblings: Siblings: Compute all pairs of siblings. The result should have the 
schema (person1, person2). Sort results by person1, breaking ties by person2. Return 
each pair once, such that the name of person1 is lexicographically lower than the name 
of person2. For example, if Ann and Bob are siblings, return (‘Ann’, ‘Bob’) only, 
do not return (‘Bob’, ‘Ann’). */
SELECT c1.child AS person1, c2.child AS person2 
FROM Parents_Children c1, Parents_Children c2
WHERE c1.parent = c2.parent AND c1.child != c2.child AND c1.child < c2.child
ORDER BY person1, person2;


/* 1B - Same generation: Compute all pairs of persons who have a common ancestor and are 
of the same generation ‘gen’ with respect to that ancestor. For a pair of siblings, gen = 1,
 because their common ancestor is a parent. Compute gen with respect to the closest common 
 ancestor (e.g., a parent is closer than a grandparent). The result should have the 
 schema (person1, person2, gen). Sort results by person1, breaking ties by person2. 
 Return each pair once, such that the name of person1 is lexicographically lower 
 than the name of person2. */
WITH RECURSIVE Tree AS (
  SELECT parent, child as pair, 1 AS gen FROM Parents_Children
  UNION
  SELECT T.parent, PC.child, T.gen + 1
  FROM Tree as T
  JOIN Parents_Children PC ON T.pair = PC.parent
) 
SELECT T1.pair AS person1, T2.pair AS person2, min(T1.gen) FROM Tree T1, Tree T2
WHERE T1.parent = T2.parent AND T1.pair < T2.pair AND T1.gen = T2.gen
GROUP BY person1, person2
ORDER BY person1, person2;


/* 1C - Same gender descendants: Compute all pairs of persons such that the first is the 
ancestor of the second and they have the same gender. We do not consider a person to be their 
own ancestor. The result should have the schema (ancestor, descendant). Sort results by ancestor, 
breaking ties by descendant. Return each ancestor-descendant pair once. */
WITH RECURSIVE Tree AS (
  SELECT parent, child as pair FROM Parents_Children
  UNION
  SELECT T.parent, PC.child
  FROM Tree as T
  JOIN Parents_Children PC ON T.pair = PC.parent
)
SELECT T.parent AS ancestor, T.pair AS descendant FROM Tree T 
JOIN Persons P1 ON T.parent = P1.name
JOIN Persons P2 ON T.pair = P2.name
WHERE P1.gender = P2.gender
ORDER BY ancestor, descendant;


/* 1D - Descendants by gender: For all persons who have a descendant, compute the number of descendants 
by gender. The result should have the schema (ancestor, gender, num_descendants). Sort results by ancestor, 
breaking ties by gender. For example, if Ann has 1 female (gender = ‘F’) and 1 male (gender = ‘M’) child, 
2 female grandchildren, and no other descendants, the result should contain 2 tuples for 
Ann: (‘Ann’, ‘F’, 3) and (‘Ann’, ‘M’, 1). */
WITH RECURSIVE Tree AS (
  SELECT parent, child as pair FROM Parents_Children
  UNION
  SELECT T.parent, PC.child
  FROM Tree as T
  JOIN Parents_Children PC ON T.pair = PC.parent
)
SELECT T.parent AS ancestor, P2.gender, COUNT(*) AS num_descendants FROM Tree T
JOIN Persons P1 ON T.parent = P1.name
JOIN Persons P2 ON T.pair = P2.name
GROUP BY T.parent, P2.gender
ORDER BY ancestor, P2.gender;


/* 1E - Relatives: Compute all pairs of relatives. Ann and Bob are relatives if Ann is a parent or ancestor 
of Bob, or if Bob is a parent or an ancestor of Ann, or if they are siblings, or if they have a common 
ancestor, no matter how far removed. The result should have the schema (person1, person2). Sort results 
by person1, breaking ties by person2. Return each pair once, such that the name of person1 is lexicographically 
lower than the name of person2. */
WITH RECURSIVE Tree AS (
  SELECT parent, child as pair, 1 AS gen FROM Parents_Children
  UNION
  SELECT T.parent, PC.child, T.gen + 1
  FROM Tree as T
  JOIN Parents_Children PC ON T.pair = PC.parent
)
SELECT T.parent AS person1, T.pair AS person2 FROM Tree T
UNION
SELECT T1.pair AS person1, T2.pair AS person2 FROM Tree T1, Tree T2
WHERE T1.parent = T2.parent AND T1.pair < T2.pair AND T1.gen = T2.gen
GROUP BY person1, person2
ORDER BY person1, person2;
