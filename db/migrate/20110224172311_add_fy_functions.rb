class AddFyFunctions < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute "
-- ensure that the plpgsql language exists
CREATE OR REPLACE FUNCTION public.create_plpgsql_language ()
        RETURNS TEXT
        AS $$
            CREATE LANGUAGE plpgsql;
            SELECT 'language plpgsql created'::TEXT;
        $$
LANGUAGE 'sql';

SELECT CASE WHEN
              (SELECT true::BOOLEAN
                 FROM pg_language
                WHERE lanname='plpgsql')
            THEN
              (SELECT 'language already installed'::TEXT)
            ELSE
              (SELECT public.create_plpgsql_language())
            END;

DROP FUNCTION public.create_plpgsql_language ();


create function fiscal_year(date) returns int as $$ 
DECLARE
  date ALIAS FOR $1;
  month integer;
BEGIN
month := date_part('month', date);
return date_part('year', date) + case when month < 7 then 0 else 1 end ;
END 
$$ LANGUAGE plpgsql IMMUTABLE;

create function fiscal_month(date) returns int as $$ 
DECLARE
  date ALIAS FOR $1;
  month integer;
BEGIN
month := date_part('month', date);
return 1 + (month + 5) % 12;
END 
$$ LANGUAGE plpgsql IMMUTABLE;

"
  end

  def self.down
ActiveRecord::Base.connection.execute "
drop function fiscal_year(date);
drop function fiscal_month(date);
"
  end
end
