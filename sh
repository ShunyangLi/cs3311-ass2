#!/usr/bin/php
<?php

error_reporting( E_ALL&~E_NOTICE );
require("a2.php");

// PROGRAM BODY BEGINS

$usage = "Usage: $argv[0] Actor Actor";
$db = dbConnect(DB_CONNECTION);

// Check arguments
if (count($argv) < 2) exit("$usage\n");

// firstly, we need get the actor
$first_actor = $argv[1];
$second_actor = $argv[2];

$get_actor_id = <<<ACTORID
    SELECT id FROM actor where lower(name) = lower(%s);
ACTORID;

$actor1 = dbNext(dbQuery($db, mkSQL($get_actor_id, $first_actor)));
$actor2 = dbNext(dbQuery($db, mkSQL($get_actor_id, $second_actor)));



$query = <<<QUERY
    drop index if exists ac;
    create index ac on acting(actor_id, movie_id);
    drop index if exists m;
    create index m on movie(id, title, year);
    
    create or replace view degrees(degree, actors) as
      select 1, array_agg(a.id)::int[] from actor a where a.id in (WITH RECURSIVE path (movie_id, d, vv) AS (
            SELECT ac.movie_id, 1, array [ac.actor_id]
            FROM acting ac
            WHERE actor_id = %d

            UNION ALL

            SELECT ac.movie_id, p.d + 1, vv||ac.actor_id
            FROM path p, acting ac
            WHERE ac.movie_id = p.movie_id
              and not (ac.actor_id = any(vv))
            AND p.d < 2
    )
    SELECT unnest(vv) FROM path where d > 1 and id != %d order by lower(name) ASC);

    create or replace function find_degree(start_value integer, end_value integer, temp_value int[], last_to int[]) 
      returns table (ds integer, ac int[]) as $$
      DECLARE
        tempactors int[];
        newactors text[];
      begin
          tempactors = temp_value;
            
          select array_agg(distinct actor_id) into newactors from acting
            where movie_id in (select distinct movie_id from acting where actor_id in (select unnest(tempactors)))
            and actor_id not in (select (unnest(last_to))::integer) and actor_id != %d;
            
          return query select start_value, tempactors;
            
          if start_value < end_value then
            return query select * from find_degree(start_value + 1, end_value, newactors::int[], array_cat(last_to, newactors::int[])::int[]);
          end if;
      end;
    $$ language plpgsql;
    
    create or replace view movies_actors as
      select act.movie_id, array_agg(act.actor_id) as actors
      from acting act group by act.movie_id;

    create or replace view des as
        select 0 as ds, array [%d]::int[] as ac union all
        select * from find_degree(1, 6, (select actors from degrees where degree = 1), (select actors from degrees where degree = 1));
        
    
    create or replace function test_find_all_actors(d int, to_value int[]) returns table (_from int, _to int) as $$
      DECLARE
        _to int[];
      BEGIN
        select array_agg(distinct actor_id)::int[] into _to from acting where  movie_id in
              (select movie_id from acting where actor_id in (select unnest(to_value)))
        and (actor_id in (select unnest(ac)::integer from des where ds = d - 1));
    
        return query select distinct actor_id, main_id from acting join (select unnest(to_value) as main_id) main_ac
            on movie_id in
                  (select movie_id from acting where actor_id in (main_ac.main_id))
            and (actor_id in (select unnest(ac)::integer from des where ds = d - 1));
    
        IF d - 1 > 0 then
          return query select * from test_find_all_actors(d - 1, _to::int[]);
        end if;
    
      end;
    $$ language plpgsql;
    
    create or replace view new_test as
        select _from as _from, _to as _to from test_find_all_actors( (select ds from des where (%d = any(ac))), array [%d]::int[]);
        
    create or replace view movies_actors as
      select act.movie_id, array_agg(act.actor_id) as actors
      from acting act group by act.movie_id;

QUERY;

dbQuery($db, mkSQL($query, $actor1[0], $actor1[0], $actor1[0], $actor1[0], $actor2[0], $actor2[0]));

$query = <<<GET
with recursive dist(_from,_to,vv) as (
      -- initial set
      select _from, _to,  array[_from, _to] from new_test
        where _from= %d
    union all
      -- recursively built set
      select d._from,tm._to,vv||tm._to
        from dist d, new_test tm
        where d._to=tm._from
          and not (tm._to = any(vv))
  )
  select vv from dist
    where _to = %d;
GET;

$result = [];
$final = [];
$temp = [];
$last = [];


// $res = dbQuery($db, mkSQL($query, $actor1[0],$actor2[0]));

$all_actors = dbQuery($db, mkSQL($query, $actor1[0],$actor2[0]));
$num = 1;
while ($res = dbNext($all_actors)) {
     // print_r($res);
    $str = str_replace('{','',$res[0]);
    $str = str_replace('}','',$str);
    $res = explode(',', $str);
    $final = show_res($db, $res, $result, $final, $temp);
}

if (count($final) > 1) {
    for ($i = 0; $i < count($final); $i ++) {
        array_push($last, join("; ", $final[$i]));
    }
} else {
    $last = $final[0];
}

sort($last);
for ($i = 0; $i < count($last); $i ++) {
    echo "$num. ";
    print($last[$i]);
    echo "\n";
    $num ++;
}


function show_res($db,$res, $result, $final, $temp) {

    for ($i = 0; $i < count($res) - 1; $i ++) {
        // echo "$res[$i] ".$res[$i+1]."\n";
        $temp_search = search_res($db, $res[$i], $res[$i+1]);
        if (count($temp_search) != 0)
            array_push($result, $temp_search);
        // print_r($result);
    }

    if (count($result) == 1) {
        return $result;
    }

    return enumerate($result,$temp,$final);
}

function enumerate($input, $current, $result, $index = 0) {

    if (count($current) == count($input)) {
        array_push($result, $current);
    } else {
        for ($i = 0; $i < count($input[$index]); $i ++) {
            array_push($current, $input[$index][$i]);
            $result = enumerate($input, $current, $result, $index + 1);
            array_pop($current);
        }
    }
    return $result;
}

function search_res($db,$a1, $a2) {

    $query = <<<SEARCH
    SELECT movie_id from movies_actors where  (%d = any(actors)) and (%d = any(actors))
SEARCH;
    $res = dbQuery($db, mkSQL($query, $a1, $a2));
    $merge = [];

    while ($tuple = dbNext($res)) {
        $get_title = <<<TITLE
        select title, year from movie where id = %d
TITLE;
        $movie = dbNext(dbQuery($db, mkSQL($get_title, $tuple[0])));
        array_push($merge, get_actor_name($db,$a1)." was in $movie[0] ($movie[1]) with ".get_actor_name($db, $a2));

    }
    // print_r($merge);
    return $merge;

}


function get_actor_name($db, $ac) {
    $query = <<<SEARCH
    SELECT name from actor where id = %d
SEARCH;
    $res = dbNext(dbQuery($db, mkSQL($query, $ac)));

    return $res[0];
}

$query = <<<DROP
    drop index ac;
    drop index m;
DROP;

dbQuery($db, mkSQL($query));

?>
