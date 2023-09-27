psql -U postgres -h localhost redmine

select * from journals;

select * from journals where journalized_id = 9;

 id  | journalized_id | journalized_type | user_id | notes |         created_on         | private_notes |         updated_on         | updated_by_id 
-----+----------------+------------------+---------+-------+----------------------------+---------------+----------------------------+---------------
  11 |              9 | Issue            |       1 |       | 2023-09-26 15:47:41.144655 | f             | 2023-09-26 15:47:41.144655 |              
 178 |              9 | Issue            |       1 |       | 2023-09-26 17:28:25.338682 | f             | 2023-09-26 17:28:25.338682 |              
 179 |              9 | Issue            |       1 |       | 2023-09-26 17:28:34.670167 | f             | 2023-09-26 17:28:34.670167 |    

 select * from journal_details where journal_id in (select id from journals where journalized_id = 9);

 id  | journal_id | property |  prop_key  | old_value | value 
-----+------------+----------+------------+-----------+-------
  11 |         11 | attr     | parent_id  |           | 8
 197 |        178 | attr     | done_ratio | 0         | 100
 198 |        179 | attr     | status_id  | 1         | 5

 update journals set created_on='2022-11-14' where id = 178;