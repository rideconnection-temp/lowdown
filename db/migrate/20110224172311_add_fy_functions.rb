class AddFyFunctions < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute "
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
