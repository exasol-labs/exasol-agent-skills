# Exasol SQL Grammar (complete, authoritative)

> **Source of truth.** This is the *complete* supported Exasol SQL grammar in
> EBNF, vendored verbatim from
> [`exasol/sql-syntax-diagrams`](https://github.com/exasol/sql-syntax-diagrams) — the same source
> the syntax-diagram images on docs.exasol.com are generated from (via
> `Ebnf2ps`). Prefer these rules over inferring syntax from examples: they
> define **every** legal clause, its ordering, and its repetition.
>
> - **DB version:** branch `master` (`master` = major version 8, incl. 2025; `R7.1` = 7.1)
> - **Source commit:** `27ab185403619f8f1e37dfeb9b3cd6287a60047b`
> - **Regenerate:** run `scripts/build_grammar.sh master` (see below). Do not hand-edit.

## How to read this notation

The source uses the `Ebnf2ps` dialect. It is **not** standard EBNF — note the
repetition operators carefully:

| Notation | Meaning |
| --- | --- |
| `a = b ;` | definition of `a` |
| `(a b)` | group (only to scope `\|` or extend `+` / `/`) |
| `a \| b` | alternative (a **or** b) |
| `[a]` | optional (zero or one) |
| `{a}` | zero or more repetitions of a **single element** (⚠ reads right-to-left; never use for a group) |
| `[(a b)+]` | zero or more repetitions of a **group** |
| `a+` | one or more repetitions |
| `a / sep` | **one or more** repetitions of `a` separated by `sep` (e.g. `expr / ","` = comma-separated list) |
| `[a / sep]` | **zero or more** repetitions of `a` separated by `sep` |
| `"string"` | terminal — appears literally in the query (one terminal per token: `"(" ")"`, not `"()"`) |

⚠ The most common misreadings for an agent: `/` is a **separated list**, not
division; `{a}` is repetition of one element only. Keep both in mind.

Rule names in a few files are German (`datentypen` = data types, `literale` =
literals, `sonstige` = miscellaneous) — cosmetic; the terminals are the real SQL.

---

## Query language (SELECT / DQL)

<sub>source: `diagrams/dql.bnf`</sub>

```ebnf
  select_statement_1
        = [ with_clause ] "SELECT" select_list [ "FROM" (from_item / ",") ] ;

  select_statement_2
        = ["WHERE" condition] [connect_by_clause] [preferring_clause] ;

  select_statement_3
        = [group_by_clause] [window_clause] ["QUALIFY" condition] ;

  select_statement_4
        = [order_by_clause] [limit_clause];

  with_clause
        = "WITH" (query_name [ "(" column_alias / "," ")" ] "AS" "(" subquery ")" ) / "," ; 

  select_list
        = ["DISTINCT" | "ALL"] ((expr [["AS"] column_alias] | ((table | view) "." "*") | "*") / ",") ;

  from_item
        = (((["TABLE"] table | view | ( "(" (subquery | subimport | values_table | value_range_table) ")" ) ) [["AS"] table_alias ["(" column_alias / "," ")"]]) | (join_clause | "(" join_clause ")")) ;

  connect_by_clause
        = ("CONNECT" "BY" ["NOCYCLE"] (condition / "AND") ["START" "WITH" condition]) | ("START" "WITH" condition "CONNECT" "BY" ["NOCYCLE"] (condition / "AND"));

  preferring_clause
        = "PREFERRING" preference_term ["PARTITION" "BY" (expr / ",") ];

  preference_term
        = "(" preference_term ")" | (("HIGH" | "LOW") expr) | (boolean_expr) | (preference_term ("PLUS" | ("PRIOR" "TO")) preference_term) | "INVERSE" "(" preference_term ")";

  group_by_clause
        = "GROUP" "BY" ((expr | position | cube_rollup_clause | grouping_sets_clause | "(" ")") / ",") ["HAVING" condition] ;

  cube_rollup_clause
        = ("CUBE" | "ROLLUP") "(" grouping_expression_list  ")" ;

  grouping_sets_clause
        = "GROUPING" "SETS" "(" (cube_rollup_clause | (grouping_expression_list)) / "," ")" ;

  grouping_expression_list
        = ((expr) | ("(" expr / "," ")")) / "," ;

  order_by_clause
        = "ORDER" "BY" ((expr | position | column_alias) ["ASC" | "DESC"] [("NULLS" ("FIRST" | "LAST"))]) / "," ;

  limit_clause
        = "LIMIT" (([offset ","] count) | (count ["OFFSET" offset])) ;

  join_clause
        = from_item (inner_outer_clause | ("CROSS" "JOIN" from_item));

  inner_outer_clause
        = ((["INNER"]) | (("LEFT" | "RIGHT") ["OUTER"]) | ("FULL" "OUTER")) "JOIN" from_item (("ON" condition) | ("USING" "(" column / "," ")"));

  subimport
        = "IMPORT" ["INTO" "(" import_columns ")"] "FROM" (dbms_src | file_src | script_src) [error_clause] ;

  values_table
        = "VALUES"  ( "(" expr / "," ")" ) / "," ;

  value_range_table
        = "VALUES" "BETWEEN" min_value "AND" max_value ["WITH" "STEP" step_value] ;

  table_operator_1
	= [with_clause] ( ( subquery | table_operator ) | "(" ( subquery | table_operator ) ")") ("UNION" ["ALL"] | "INTERSECT" | ("EXCEPT" | "MINUS"));

  table_operator_2
	= (subquery | "(" subquery ")") [order_by_clause] [limit_clause] ;

```

---

## Data manipulation (INSERT / UPDATE / DELETE / MERGE / TRUNCATE — DML)

<sub>source: `diagrams/dml.bnf`</sub>

```ebnf
  insert_statement_1
	= "INSERT" "INTO" table [ ["AS"] t_alias ] [ ( "(" column / "," ")" ) ];

  insert_statement_2
        = ( "VALUES"  ( "(" (expr | "DEFAULT") / "," ")") / "," ) | ( "VALUES" "BETWEEN" min_value "AND" max_value ["WITH" "STEP" step_value] ) | "DEFAULT" "VALUES" | subquery;

  update_statement_1
	= "UPDATE" table [ ["AS"] t_alias ];

  update_statement_2
        = "SET" ((col "=" ( expr | "DEFAULT" )) / "," ) ["FROM" from_item / ","];

  update_statement_3
        = ["WHERE" condition] ["PREFERRING" preferring_term] ;

  delete_statement_1
        = "DELETE" [ "*" ] "FROM" table [["AS"] t_alias];

  delete_statement_2
        = ["WHERE" condition] ["PREFERRING" preferring_term] ;

  truncate_statement
        = "TRUNCATE" "TABLE" table;

  merge_statement_1
	= "MERGE" "INTO" table [ ["AS"] t_alias ];

  merge_statement_2
        = "USING" (table | view | subquery) [ ["AS"] t_alias ] "ON" condition;

  merge_statement_3
        = [ "WHEN" "MATCHED" "THEN" (merge_update_clause | merge_delete_clause) ];

  merge_statement_4
        = [ "WHEN" "NOT" "MATCHED" "THEN" merge_insert_clause ];

  merge_update_clause_1
        = "UPDATE" "SET" ((column "=" ( expr | "DEFAULT" ) ) / "," ) [ where_clause ];

  merge_update_clause_2
        = [ "DELETE" [where_clause] ];

  merge_delete_clause
        = "DELETE" [ where_clause ];

  merge_insert_clause_1
        = "INSERT" [ "(" column / "," ")" ]  "VALUES" "(" (expr | "DEFAULT") / "," ")";

  merge_insert_clause_2
        = [ where_clause ];
  
```

---

## Data definition (CREATE / ALTER / DROP — DDL)

<sub>source: `diagrams/ddl.bnf`</sub>

```ebnf
  create_schema_statement
        = "CREATE" "SCHEMA" ["IF" "NOT" "EXISTS"] schema;

  create_virtual_schema_statement_1
        = "CREATE" "VIRTUAL" "SCHEMA" ["IF" "NOT" "EXISTS"] schema;

  create_virtual_schema_statement_2
        = "USING" adapter [ "WITH" ( property "=" string )+ ];

  alter_schema_statement
        = "ALTER" "SCHEMA" schema (("CHANGE" "OWNER" ( user | role )) | ("SET" "RAW_SIZE_LIMIT" "=" limit_in_bytes));

  alter_virtual_schema_statement_1
        = "ALTER" "VIRTUAL" "SCHEMA" schema;

  alter_virtual_schema_statement_2
       = ( "SET" ( property "=" string )+ ) | ( "REFRESH" [ "TABLES" ( table )+ ] ) | ( "CHANGE" "OWNER" ( user | role ) );

  drop_schema_statement_1
        = "DROP" [["FORCE"] "VIRTUAL"] "SCHEMA";

  drop_schema_statement_2
        = ["IF" "EXISTS"] schema [ ( "CASCADE" | "RESTRICT" )];

  create_table_statement_1
        = "CREATE" [ "OR" "REPLACE" ] "TABLE" [ "IF" "NOT" "EXISTS"] table;

  create_table_statement_2
        = ("(" ((column_definition | like_clause | out_of_line_constraint) / ",") ["," (distribute_by | partition_by) / ","] ")") | like_clause | ("AS" subquery [ ("WITH" "DATA") | ("WITH" "NO" "DATA" )] );

  create_table_statement_3
        = ["COMMENT" "IS" string];

  column_definition_1
        = column datatype [ "DEFAULT" expr | "IDENTITY" [ int ] ] { inline_constraint };

  column_definition_2
        = ["COMMENT" "IS" string];

  inline_constraint
        = ["CONSTRAINT" [name]] ( (["NOT"] "NULL") | ("PRIMARY" "KEY") | (references_clause) ) ["ENABLE" | "DISABLE"] ;
  
  out_of_line_constraint_1
        = ["CONSTRAINT" [constraint]];

  out_of_line_constraint_2
        = ( ("PRIMARY" "KEY" "(" column / "," ")" ) | ("FOREIGN" "KEY" "(" column / "," ")" references_clause) ) ["ENABLE" | "DISABLE"];

  references_clause
        = "REFERENCES" table ["(" column / "," ")"];

  like_clause
        = "LIKE" (table | view) ["(" (column [["AS"] alias]) / "," ")"];

  like_clause_2
        = [(("INCLUDING" | "EXCLUDING") "DEFAULTS")] [(("INCLUDING" | "EXCLUDING") "IDENTITY") ] ;

  like_clause_3
        = [(("INCLUDING" | "EXCLUDING") "COMMENTS") ];

  distribute_by
        = "DISTRIBUTE" "BY" (column / ",") ;

  partition_by
        = "PARTITION" "BY" (column / ",") ;

  select_into_statement_1
        = "SELECT" select_list "INTO" "TABLE" table "FROM" from_item / ",";

  drop_table_statement_1
        = "DROP" "TABLE" ["IF" "EXISTS"] table;

  drop_table_statement_2
        = [ ( "CASCADE" | "RESTRICT" )] ["CASCADE" "CONSTRAINTS"];

  alter_column_statement
        = "ALTER" "TABLE" table (add_column | drop_column | modify_column | rename_column | alter_column_default | alter_column_identity);

  add_column_statement_1
	= "ADD" [ "COLUMN" ] ["IF" "NOT" "EXISTS"] column datatype;

  add_column_statement_2
        = [ ("DEFAULT" expr) | ("IDENTITY" [int]) ] [inline_constraint];

  drop_column_statement
        = "DROP" [ "COLUMN" ] ["IF" "EXISTS"] column [ "CASCADE" "CONSTRAINTS" ];

  modify_column_statement_1
        = "MODIFY" [ "COLUMN" ] column [datatype];

  modify_column_statement_2
        = [ ("DEFAULT" expr) | ("IDENTITY" [int]) ] [inline_constraint];

  rename_column_statement
        = "RENAME" "COLUMN" old_name "TO" new_name;

  alter_column_default_statement
	= "ALTER" [ "COLUMN" ] column ( ( "SET" "DEFAULT" expr ) | ( "DROP" "DEFAULT" ) );

  alter_column_identity_statement
	= "ALTER" [ "COLUMN" ] column ( ( "SET" "IDENTITY" [int] ) | ( "DROP" "IDENTITY" ) );

  alter_table_distribute_partition
    = "ALTER" "TABLE" table (( (("DISTRIBUTE" | "PARTITION") "BY" (column / ",")) / ",") | ("DROP" (("DISTRIBUTION" | "PARTITION") / "AND") "KEYS"));

  alter_table_constraint
        = "ALTER" "TABLE" table (("ADD" out_of_line_constraint) | ("MODIFY" (("CONSTRAINT" constraint) | ("PRIMARY" "KEY")) ("ENABLE" | "DISABLE") ) | ("DROP" (("CONSTRAINT" constraint) | ("PRIMARY" "KEY"))) | ("RENAME" "CONSTRAINT" old_name "TO" new_name) );

  create_view_statement
        = "CREATE" [ "OR" "REPLACE" ] [ "FORCE" ] "VIEW" view;

  create_view_statement2
        = [ "(" [column ["COMMENT" "IS" string]] / "," ")"] "AS" subquery;

  create_view_statement3
        = ["COMMENT" "IS" string];

  drop_view_statement
        = "DROP" "VIEW" ["IF" "EXISTS"] view [ ( "CASCADE" | "RESTRICT" )];

  create_function_statement_1
        = ["CREATE" ["OR" "REPLACE"]] "FUNCTION" function;

  create_function_statement_2
        = "(" [(param ["IN"] data_type) / ","] ")" "RETURN" data_type;

  create_function_statement_3
        = ["IS"] (variable data_type ";")+;

  create_function_statement_4
        = "BEGIN" function_statement+ "RETURN" expr ";";

  create_function_statement_5
        = "END" [function] [";"];

  create_function_statement_6
        = "/";

  function_statement
        = assignment | if_branch | for_loop | for_loop_2 | while_loop | ("RETURN" expr ";");

  assignment      
        = identifier ":=" expr ";";
 
  if_branch_1
        = "IF" condition "THEN" function_statement+ ;

  if_branch_2
        = [(("ELSEIF" | "ELSIF") condition "THEN" function_statement+)+];

  if_branch_3
        = ["ELSE" function_statement+] "END" "IF" ";";

  while_loop
        = "WHILE" condition "DO" function_statement+ "END" "WHILE" ";" ;

  for_loop_1
        = "FOR" identifier ":=" int "TO" int;

  for_loop_2
        = "DO" function_statement+ "END" "FOR" ";" ;

  for_loop_11
        = "FOR" identifier "IN" int ".." int;

  for_loop_12
        = "LOOP" function_statement+ "END" "LOOP" ";" ;

  drop_function_statement
        = "DROP" "FUNCTION" ["IF" "EXISTS"] function [ ( "CASCADE" | "RESTRICT" )];


  create_script_content
        = script_content;

  create_script_terminator
        = "/";


  create_script_program_statement_1
        = "CREATE" [ "OR" "REPLACE" ] [ "LUA" ] "SCRIPT" script;

  create_script_program_statement_2
        = [ "(" [ ( [ "ARRAY" ] param_name ) / "," ] ")" ];

  create_script_program_statement_3
        = [ "RETURNS" "TABLE" | "RETURNS" "ROWCOUNT" ] "AS";


  create_script_udf_statement_1
        = "CREATE" [ "OR" "REPLACE" ] ( "JAVA" | "LUA" | "PYTHON3" | "R" | alias );

  create_script_udf_statement_2
        = ( "SCALAR" | "SET" ) "SCRIPT" script;

  create_script_udf_statement_3
        = "(" [ ( param_name data_type ) / "," [ udf_order_by_clause ] | "..." ] ")";

  create_script_udf_statement_4
        = [ "[" "USING" "INPUT" "COLUMN" "NAMES" "]" ];

  create_script_udf_statement_5
        = ( "RETURNS" data_type | "EMITS" "(" ( ( param_name data_type ) / "," | "..." ) ")" ) "AS";

  create_script_udf_order_by
        = "ORDER" "BY" ( param_name [ "ASC" | "DESC" ] ["NULLS" ( "FIRST" | "LAST" ) ] ) / ",";


  create_script_adapter_statement_1
        = "CREATE" [ "OR" "REPLACE" ] ( "JAVA" | "LUA" | "PYTHON3" | alias ) "ADAPTER" "SCRIPT" script "AS";


  create_script_preprocessor_statement_1
        = "CREATE" [ "OR" "REPLACE" ] ( "JAVA" | "LUA" | "PYTHON3" | alias ) "PREPROCESSOR" "SCRIPT" script "AS";


  drop_script_statement
        = "DROP" ["ADAPTER"] "SCRIPT" ["IF" "EXISTS"] script;

  rename_statement
        = "RENAME" [ "SCHEMA" | "TABLE" | "VIEW" | "FUNCTION" | "SCRIPT" | "USER" | "ROLE" | "CONNECTION" | ("CONSUMER" "GROUP")] old_name "TO" new_name;

  comment_table_statement_1
        = "COMMENT" "ON" ["TABLE"] table ["IS" string];

  comment_table_statement_2
        = ["(" ((column "IS" string) / ",") ")"] ;

  comment_object_statement
        = "COMMENT" "ON" (("COLUMN" | "SCHEMA" | "FUNCTION" | "SCRIPT" | "USER" | "ROLE" | "CONNECTION" | ("CONSUMER" "GROUP")) object "IS" string);
```

---

## Access control (GRANT / REVOKE / roles / privileges — DCL)

<sub>source: `diagrams/dcl.bnf`</sub>

```ebnf
  create_user_statement
        = "CREATE" "USER" user "IDENTIFIED" (("BY" password) | ("BY" "KERBEROS" "PRINCIPAL" string) | ("AT" "LDAP" "AS" dn_string ["FORCE"]) | ("BY" "OPENID" "SUBJECT" string));

  alter_user_statement_1
        = "ALTER" "USER" user;

  alter_user_statement_2
        = ("IDENTIFIED" (("BY" password [ "REPLACE" old_password ]) | ("BY" "KERBEROS" "PRINCIPAL" string) | ("AT" "LDAP" "AS" dn_string) | ("BY" "OPENID" "SUBJECT" string))) | ("SET" "PASSWORD_EXPIRY_POLICY" "=" string) | ("PASSWORD" "EXPIRE") | ("RESET" "FAILED" "LOGIN" "ATTEMPTS");

  alter_user_set_consumer_group
        = "ALTER" "USER" user "SET" "CONSUMER_GROUP" "=" ( group | "NULL" );

  drop_user_statement
        = "DROP" "USER" ["IF" "EXISTS"] user ["CASCADE"];

  create_role_statement
        = "CREATE" "ROLE" role;

  alter_role_set_consumer_group
        = "ALTER" "ROLE" role "SET" "CONSUMER_GROUP" "=" ( group | "NULL" );

  drop_role_statement
        = "DROP" "ROLE" ["IF" "EXISTS"] role ["CASCADE"];

  create_connection_statement_1
        = "CREATE" ["OR" "REPLACE"] "CONNECTION" connection "TO" string;

  create_connection_statement_2
        = ["USER" user "IDENTIFIED" "BY" password];

  create_connection_statement_3
        = ["PUBLIC KEY" string] ["SESSION TOKEN" string];

  create_connection_statement_4
        = [ "CLIENT ID" client_id ] [ "TENANT ID" tenant_id ] [ "SAS TOKEN" sas_token ];

  alter_connection_statement_1
        = "ALTER" "CONNECTION" connection "TO" string;

  alter_connection_statement_2
        = ["USER" user "IDENTIFIED" "BY" password];

  alter_connection_statement_3
        = ["PUBLIC KEY" string] ["SESSION TOKEN" string];

  alter_connection_statement_4
        = [ "CLIENT ID" client_id ] [ "TENANT ID" tenant_id ] [ "SAS TOKEN" sas_token ];

  drop_connection_statement
        = "DROP" "CONNECTION" ["IF" "EXISTS"] connection;
  
  grant_sysprivs_statement1
        = "GRANT" ( "ALL" ["PRIVILEGES"] | ( system_privilege / "," ) ) "TO" ((user | role) / ",");

  grant_sysprivs_statement2
        = ["WITH" "ADMIN" "OPTION"];

  grant_role_statement
        = "GRANT" ( role / "," ) "TO" (user | role) / "," ["WITH" "ADMIN" "OPTION"];

  grant_impersonation_statement
        = "GRANT" "IMPERSONATION" "ON" ( (user | role) / "," ) "TO" ( (user | role) / "," );

  grant_connection_statement_1
        = "GRANT" "CONNECTION" ( connection / "," ) "TO" (user | role) / ",";

  grant_connection_statement_2
        = ["WITH" "ADMIN" "OPTION"];

  grant_objprivs_statement_1
        = "GRANT" ( "ALL" ["PRIVILEGES"] | ( ("SELECT" | "INSERT" | "DELETE" | "UPDATE" | "ALTER" | "REFERENCES" | "EXECUTE" | "USAGE") / "," ) ) "ON" ["SCHEMA" | "TABLE" | "VIEW" | "FUNCTION" | "SCRIPT"] object;

  grant_objprivs_statement_2
        = "TO" (user | role) / ",";

  grant_connection_restricted_statement_1
        = "GRANT" "ACCESS" "ON" "CONNECTION" connection_name ;

  grant_connection_restricted_statement_2
        = ["FOR" (udf_script_name | schema_name | "SCRIPT" udf_script_name | "SCHEMA" schema_name)] "TO" (user | role) / ",";

  revoke_sysprivs_statement
        = "REVOKE" ( "ALL" ["PRIVILEGES"] | ( system_privilege / "," ) ) "FROM" ((user | role) / "," );

  revoke_role_statement
        = "REVOKE" (( role / "," ) | ("ALL" "ROLES")) "FROM" ((user | role) / ",");

  revoke_impersonation_statement
        = "REVOKE" "IMPERSONATION" "ON" ( (user | role) / "," ) "FROM" ( (user | role) / "," );

  revoke_connection_statement
        = "REVOKE" "CONNECTION" ( connection / "," ) "FROM" ((user | role) / ",");

  revoke_objprivs_statement_1
        = "REVOKE" ( "ALL" ["PRIVILEGES"] | ( ("SELECT" | "INSERT" | "DELETE" | "IMPORT" | "EXPORT" | "UPDATE" | "ALTER" | "REFERENCES" | "EXECUTE" | "USAGE") / "," ) ) "ON" ((["SCHEMA" | "TABLE" | "VIEW" | "FUNCTION" | "SCRIPT"] object) | ("ALL" ["OBJECTS"]));

  revoke_objprivs_statement_2
        = "FROM" ((user | role) / ",") ["CASCADE" "CONSTRAINTS"];

  revoke_connection_restricted_statement_1
        = "REVOKE" "ACCESS" "ON" "CONNECTION" connection_name ;

  revoke_connection_restricted_statement_2
        = ["FOR" (udf_script_name | schema_name | "SCRIPT" udf_script_name | "SCHEMA" schema_name)] "FROM" (user | role) / ",";

```

---

## Sessions, transactions & administration (DAL)

<sub>source: `diagrams/dal.bnf`</sub>

```ebnf
select_with_invalid_primary_key1
	= "SELECT" ["DISTINCT" | "ALL"] [select_list "WITH"]
        ;

select_with_invalid_primary_key2
	=  "INVALID" "PRIMARY" "KEY" "(" column / "," ")" "FROM" table
        ;

rest_select1
	= [where_clause] [group_by_clause] [window_clause]
        ;

rest_select2
	=  ["QUALIFY" condition] [order_by_clause]
        ;


select_with_invalid_unique1
	= "SELECT" ["DISTINCT" | "ALL"] [select_list "WITH"]
        ;

select_with_invalid_unique2
	= "INVALID" "UNIQUE" "(" column / "," ")" "FROM" table
        ;

select_with_invalid_foreign_key1
	= "SELECT" ["DISTINCT" | "ALL"] [select_list "WITH"]
        ;

select_with_invalid_foreign_key2
	= "INVALID" "FOREIGN" "KEY" "(" column / "," ")" "FROM" table 
        ;

select_with_invalid_foreign_key3
	= "REFERENCING" ref_table ["(" ref_column / "," ")"]
        ;

```

---

## Bulk load & unload (IMPORT / EXPORT — ETL)

<sub>source: `diagrams/etl.bnf`</sub>

```ebnf
import_1
  = "IMPORT" ["INTO" ((table ["(" (column / ",") ")"]) | "(" import_columns ")")];

import_2
  = "FROM" ( ((dbms_src | file_src) [error_clause]) | script_src);

import_columns
  = (column datatype | ("LIKE" (table | view) ["(" (column [["AS"] alias]) / "," ")"])) / ",";

import_like_clause
  = "LIKE" (table | view) ["(" (column [["AS"] alias]) / "," ")"];


values_clause
  = "VALUES" "(" val_list ")";

dbms_src_1
  = ("EXA" | "ORA" | ("JDBC" ["DRIVER" "=" string])) connection_def;

dbms_src_2
  = ("TABLE" table ["(" column / "," ")"]) | ("STATEMENT" stmt_string)+ ;

file_src_1
  = ((("CSV" | "FBV" | "PARQUET") ((connection_def | cloud_connection_def) ("FILE" string)+ )+)  ) | ( "LOCAL" ["SECURE"] ("CSV" | "FBV") ("FILE" string)+ );

file_src_2
  = [ (csv_cols | fbv_cols | parquet_metadata_specification)] [file_opts] [cert_verification];

connection_def
  = "AT" (connection | string) [ user_identification ] [ cert_verification ] [ session_token ];

cloud_connection_def_1
  = "AT" "CLOUD" ("NONE" | "AZURE" "BLOBSTORAGE" | "AWS" "S3") (connection | string);

cloud_connection_def_2
  = [ user_identification ] [ blobstorage_authentication ];

user_identification = [ "USER" user ] [ "IDENTIFIED" "BY" password ];

blobstorage_authentication = [ "CLIENT ID" client_id ] [ "TENANT ID" tenant_id ] [ "SAS TOKEN" sas_token ];

cert_verification = [("IGNORE CERTIFICATE" | "VERIFY CERTIFICATE")] ["PUBLIC KEY" string];

session_token = "SESSION TOKEN" string;

file_import_options
  = ( ("ENCODING" "=" string) 
     | ("SKIP" "=" int) 
     | ("TRIM" | "LTRIM" | "RTRIM")
     | ("NULL" "=" string) 
     | ("ROW" "SEPARATOR" "=" string)
     | ("COLUMN" "SEPARATOR" "=" string)
     | ("COLUMN" "DELIMITER" "=" string)
     | ("ROW" "SIZE" "=" int))+
;

csv_import_cols
  = "(" (col_nr ["FORMAT" "=" string] | from_col_nr ".." to_col_nr) / "," ")";

fbv_import_cols
  = "("
    (
      (
            ("SIZE" "=" bytes) 
          | ("START" "=" int) 
          | ("FORMAT" "=" string) 
          | ("ALIGN"   "=" align) 
          | ("PADDING" "=" string)
      )+
    ) / ","
    ")";

parquet_metadata_specification
  = "WITH" (
             ("SOURCE ROW NUMBER" "=" column) 
           | ("SOURCE FILE HASH_SHA256" "=" column)
           | ("SOURCE COLUMN NAMES" "=" "(" (string / ",") ")" )
)+;

error_clause_1
  = ["ERRORS" "INTO" error_dst ["(" expr ")"] ["REPLACE" | "TRUNCATE"]] [reject_clause];

error_clause_2
  = "REJECT" "LIMIT" (int | "UNLIMITED" ) ["ERRORS"];

error_dst
  = ("CSV" (connection_def | cloud_connection_def) "FILE" string) | ("LOCAL" ["SECURE"] "CSV" "FILE" string) | (table) ;

script_src
  = "SCRIPT" script [connection_def] [ "WITH" (property "=" value)+ ];




export_1
  = "EXPORT" ((table ["(" col_list ")"]) | "(" query ")");

export_2
  = "INTO" (((dbms_dst | file_dst) [ error_clause ]) | (script_dst));

file_dst_1
  = ((("CSV" | "FBV") ((connection_def | cloud_connection_def) ("FILE" string)+)+) | ("LOCAL" ["SECURE"] ("CSV" | "FBV")) ("FILE" string)+);

file_dst_2
  = [ (csv_cols | fbv_cols)] [file_opts] [cert_verification];

file_export_opts
  = ( "REPLACE" 
     | "TRUNCATE" 
     | ("ENCODING" "=" string) 
     | ("NULL" "=" string) 
     | ("BOOLEAN" "=" string) 
     | ("ROW" "SEPARATOR" "=" string)
     | ("COLUMN" "SEPARATOR" "=" string)
     | ("COLUMN" "DELIMITER" ["=" string])
     | ("DELIMIT" "=" ("ALWAYS" | "NEVER" | "AUTO"))
     | ("WITH" "COLUMN" "NAMES")
     )+
;

dbms_dst_1
  = ("EXA" | "ORA" | ("JDBC" ["DRIVER" "=" string])) connection_def ;

dbms_dst_2
  = ("TABLE" table [ "(" column / "," ")" ] [ ("REPLACE" | "TRUNCATE" | "CREATED" "BY" string)+ ]) | ("STATEMENT" stmt_string) ;

csv_export_cols
  = "(" (col_nr ["FORMAT" "=" string] ["DELIMIT" "=" ("ALWAYS" | "NEVER" | "AUTO")] | from_col_nr ".." to_col_nr) / "," ")";

fbv_export_cols
  = "(" 
    [
      (
          ("SIZE" "=" bytes) 
        | ("FORMAT" "=" string) 
        | ("ALIGN"   "=" align) 
        | ("PADDING" "=" string)
      )+
    ] / ","
    ")";

error_clause
  = "REJECT" "LIMIT" (int | "UNLIMITED" ) ["ERRORS"];

script_dst
  = "SCRIPT" script [connection_def] [ "WITH" (property "=" value)+ ];
```

---

## Built-in functions

<sub>source: `diagrams/functions.bnf`</sub>

```ebnf
multi
  = number "*" (number | interval);

division
  = (number | interval) "/" number;

add
  = (number "+" number) | (interval "+" interval) | ((datetime) "+" (integer | interval));

sub
  = (number "-" number) | (interval "-" interval) | (date "-" (date | integer | interval) ) ;

concat_sign
  = string1 "||" string2;

prior
  = "PRIOR" expr;

connect_by_root
  = "CONNECT_BY_ROOT" expr;

analytic_function
  = function "(" [ expr [ "," expr] ] ")" [ over_clause ];

over_clause
  = "OVER" ( window_name | "(" [ window_name ] [ partition_clause ] [ order_clause ] [window_frame_clause] ")" );
    
partition_clause
  = "PARTITION" "BY" ( expr / "," );

order_clause
  = "ORDER" "BY" ( ( expr [ "DESC" | "ASC" ] [ "NULLS" ( "FIRST" | "LAST" ) ] ) / "," );

window_frame_clause
  = ( "ROWS" | "RANGE" | "GROUPS" ) ( ( "UNBOUNDED" "PRECEDING" | "CURRENT" "ROW" | expr "PRECEDING" ) | "BETWEEN" ( "UNBOUNDED" "PRECEDING" | "CURRENT" "ROW" | expr "PRECEDING" | expr "FOLLOWING") "AND" ( "CURRENT" "ROW" | expr "PRECEDING" | expr "FOLLOWING" | "UNBOUNDED" "FOLLOWING" ) ) [window_frame_exclusion];

window_frame_exclusion
  = "EXCLUDE" ( "CURRENT" "ROW" | "TIES" | "GROUP" | "NO" "OTHERS" );

named_window_specification
  = "WINDOW" ( ( window_name "AS" "(" [ previously_defined_window_name ] [ partition_clause ] [ order_clause ] [window_frame_clause] ")" ) / "," );
  
abs 
  = "ABS" "(" n ")";

acos
  = "ACOS" "(" n ")";

add_days
  = "ADD_DAYS" "(" (datetime) "," integer ")";

add_hours
  = "ADD_HOURS" "(" datetime "," integer ")";

add_minutes
  = "ADD_MINUTES" "(" datetime "," integer ")";

add_months
  = "ADD_MONTHS" "(" (datetime) "," integer ")";

add_seconds
  = "ADD_SECONDS" "(" datetime "," decimal ")";

add_weeks
  = "ADD_WEEKS" "(" (datetime) "," integer ")";

add_years
  = "ADD_YEARS" "(" (datetime) "," integer ")";

any
  = "ANY" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

approximate_count_distinct
  = "APPROXIMATE_COUNT_DISTINCT" "(" expr ")";

ascii
  = "ASCII" "(" char ")";

unicode
  = "UNICODE" "(" char ")";

asin
  = "ASIN" "(" n ")";

atan
  = "ATAN" "(" n ")";

atan2
  = "ATAN2" "(" n "," m ")";

avg 
  = "AVG" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

bit_and
  = "BIT_AND" "(" integer "," integer ")";

bit_check
  = "BIT_CHECK" "(" integer "," pos ")"; 

bit_length
  = "BIT_LENGTH" "(" string ")";

bit_lrotate
  = "BIT_LROTATE" "(" integer "," integer ")";

bit_lshift
  = "BIT_LSHIFT" "(" integer "," integer ")";

bit_not
  = "BIT_NOT" "(" integer ")";

bit_or
  = "BIT_OR" "(" integer "," integer ")";

bit_rrotate
  = "BIT_RROTATE" "(" integer "," integer ")";

bit_rshift
  = "BIT_RSHIFT" "(" integer "," integer ")";

bit_to_num
  = "BIT_TO_NUM" "(" digit / "," ")";

bit_set
  = "BIT_SET" "(" integer "," pos ")"; 

bit_xor
  = "BIT_XOR" "(" integer "," integer ")";

case
  = "CASE" (simple_case_expr | searched_case_expr )  "END";

simple_case_expr
  = expr ("WHEN" comparison_expr "THEN" result)+ ["ELSE" expr];

searched_case_expr
  = ("WHEN" condition "THEN" result)+ ["ELSE" expr];
 
cast
  = "CAST" "(" expr "AS" data_type ")";

ceil
  = ("CEIL" | "CEILING") "(" number ")";

character_length
  = "CHARACTER_LENGTH" "(" string ")";

chr
  = ("CHR" | "CHAR") "(" integer ")";

coalesce
  = "COALESCE" "(" (expr / ",") ")";

cologne_phonetic
  = "COLOGNE_PHONETIC" "(" string ")";

concat
  = "CONCAT" "(" string / "," ")";

connect_by_iscycle
  = "CONNECT_BY_ISCYCLE";

connect_by_isleaf
  = "CONNECT_BY_ISLEAF";

convert
  = "CONVERT" "(" data_type "," expr ")";

convert_tz
  = "CONVERT_TZ" "(" datetime "," from_tz "," to_tz ["," options] ")";

corr
  = "CORR" "(" expr1 "," expr2 ")" [ over_clause ]; 

cos
  = "COS" "(" n ")";

cosh
  = "COSH" "(" n ")";

cot
  = "COT" "(" n ")";

count
  = "COUNT" "(" ( "*" | ( [ ( "DISTINCT" | "ALL" ) ] ( expr | ( "(" ( expr / "," ) ")" ) ) ) ) ")" [ over_clause ];

covar_pop
  = "COVAR_POP" "(" expr1 "," expr2 ")" [ over_clause ]; 

covar_samp
  = "COVAR_SAMP" "(" expr1 "," expr2 ")" [ over_clause ]; 

cume_dist
  = "CUME_DIST" "(" ")" over_clause; 

curdate
  = "CURDATE" "(" ")";

current_cluster
  = "CURRENT_CLUSTER";

current_date
  = "CURRENT_DATE";

current_schema
  = "CURRENT_SCHEMA";

current_session
  = "CURRENT_SESSION";

current_statement
  = "CURRENT_STATEMENT";

current_timestamp
  = "CURRENT_TIMESTAMP" [ "(" [ precision ] ")" ];

current_user
  = "CURRENT_USER";

date_trunc
  = "DATE_TRUNC" "(" format "," (datetime ) ")";

day1
  = "DAY" "(" date ")";

dayofweek
  = "DAYOFWEEK" "(" datetime ")";

days_between
  = "DAYS_BETWEEN" "(" (datetime1) "," (datetime2) ")";

dbtimezone
  = "DBTIMEZONE";

decode
  = "DECODE" "(" expr "," ((search "," result) / ",") ["," default] ")";

dense_rank
  = "DENSE_RANK" "(" ")" over_clause;

every
  = "EVERY" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

degrees
  = "DEGREES" "(" n ")";

div
  = "DIV" "(" m "," n ")";

dump
  = "DUMP" "(" string ["," format ["," start ["," length ] ] ] ")";

edit_distance
  = "EDIT_DISTANCE" "(" string "," string ")";

exp
  = "EXP" "(" n ")";

extract
  = "EXTRACT" "(" ("YEAR" | "MONTH" | "DAY" | "HOUR" | "MINUTE" | "SECOND") "FROM" (datetime | interval) ")";

first_value
  = "FIRST_VALUE" "(" expr ")" [ ( "RESPECT" | "IGNORE" ) "NULLS" ] [ over_clause ];

floor
  = "FLOOR" "(" n ")";

from_posix_time
  = "FROM_POSIX_TIME" "(" number ")";

greatest
  = "GREATEST" "(" ( expr / "," ) ")";

group_concat
  = "GROUP_CONCAT" "(" [ "DISTINCT" ] expr [ order_clause ] [ "SEPARATOR" separator ] ")" [ over_clause ];

grouping
  = ("GROUPING" | "GROUPING_ID") "(" expr / "," ")";

hash_md5
  = "HASH_MD5" "(" expr / "," ")";

hash_sha1
  = ("HASH_SHA1" | "HASH_SHA") "(" expr / "," ")";

hash_sha256
  = "HASH_SHA256" "(" expr / "," ")";

hash_sha512
  = "HASH_SHA512" "(" expr / "," ")";

hash_tiger
  = "HASH_TIGER" "(" expr / "," ")";

hashtype_md5
  = "HASHTYPE_MD5" "(" expr / "," ")";

hashtype_sha1
  = ("HASHTYPE_SHA1" | "HASHTYPE_SHA") "(" expr / "," ")";

hashtype_sha256
  = "HASHTYPE_SHA256" "(" expr / "," ")";

hashtype_sha512
  = "HASHTYPE_SHA512" "(" expr / "," ")";

hashtype_tiger
  = "HASHTYPE_TIGER" "(" expr / "," ")";

hour1
  = "HOUR" "(" datetime ")";

hours_between
  = "HOURS_BETWEEN" "(" timestamp1 "," timestamp2 ")";

if_then_else
  = "IF" condition "THEN" expr [ "ELSE" expr ] "ENDIF";

ifnull
  = "IFNULL" "(" expr1 "," expr2 ")";

initcap
  = "INITCAP" "(" string ")";

insert
  = "INSERT" "(" string "," position "," length "," new_string ")";

instr
  = "INSTR" "(" string "," search_string ["," position ["," occurence]]")";

iproc
  = "IPROC" "(" ")";

is_datatype
  = (("IS_NUMBER" | "IS_DATE" | "IS_TIMESTAMP") "(" string [ "," format ]")") | (("IS_BOOLEAN" | "IS_DSINTERVAL" | "IS_YMINTERVAL") "(" string ")" ) ;

lag
  = "LAG" "(" expr [ "," offset [ "," default ] ] ")" [ ( "RESPECT" | "IGNORE" ) "NULLS" ] over_clause;

last_value
  = "LAST_VALUE" "(" expr ")" [ ( "RESPECT" | "IGNORE" ) "NULLS" ] [ over_clause ];

last_day
  = "LAST_DAY" "(" datetime ")";

lcase
  = "LCASE" "(" string ")";

lead
  = "LEAD" "(" expr [ "," offset [ "," default ] ] ")" [ ( "RESPECT" | "IGNORE" ) "NULLS" ] over_clause;

least
  = "LEAST" "(" (expr / ",") ")";

left  
  = "LEFT"  "(" string "," length ")" ;

length
  = "LENGTH" "(" string ")";

level
  = "LEVEL";

listagg_1
  = "LISTAGG" "(" [ "DISTINCT" | "ALL" ] expr [ "," delimiter ] [ listagg_overflow ] ")";

listagg_2
  = [ "WITHIN" "GROUP" "(" order_clause ")" ] [ over_clause ];

listagg_overflow
  = "ON" "OVERFLOW" ( "ERROR" | "TRUNCATE" [ truncation_filler ] ( "WITH" | "WITHOUT" ) "COUNT" );

ln
  = "LN" "(" n ")";

localtimestamp
  = "LOCALTIMESTAMP" [ "(" [ precision ] ")" ];

locate
  = "LOCATE" "(" search_string "," string ["," position]")";

log
  = "LOG" "(" base "," n ")";

log10
  = "LOG10" "(" n ")";

log2
  = "LOG2" "(" n ")";

lower
  = "LOWER" "(" string ")";

lpad
  = "LPAD" "(" string "," n [ "," padding ]")";

ltrim
  = "LTRIM" "(" string ["," trim_chars ] ")";

max
  = "MAX" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

median
  = "MEDIAN" "(" [ "ALL" ] expr ")" [ over_clause ];

mid  
  = "MID"  "(" string ","  position [ "," length]")" ;

min
  = "MIN" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

minute1
  = "MINUTE" "(" datetime ")";

minutes_between
  = "MINUTES_BETWEEN" "(" timestamp1 "," timestamp2 ")";

min_scale
  = "MIN_SCALE" "(" exact_numeric ")";

mod
  = "MOD" "(" m "," n ")";

month1
  = "MONTH" "(" date ")";

months_between
  = "MONTHS_BETWEEN" "(" (datetime1) "," (datetime2) ")";

mul
  = "MUL" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

nullif
  = "NULLIF" "(" expr1 "," expr2 ")";

nullifzero
  = "NULLIFZERO" "(" number ")";

numtodsinterval
  = "NUMTODSINTERVAL" "(" n "," "'" interval_unit "'" ")";

numtoyminterval
  = "NUMTOYMINTERVAL" "(" n "," "'" interval_unit "'" ")";

now
  = "NOW" "(" ")";

nproc
  = "NPROC" "(" ")";

nth_value
  = "NTH_VALUE" "(" expr "," n ")" [ "FROM" ( "FIRST" | "LAST" ) ] [ ( "RESPECT" | "IGNORE" ) "NULLS" ] over_clause;

ntile
  = "NTILE" "(" expr ")" over_clause;

nvl
  = "NVL" "(" expr1 "," expr2 ")";

nvl2
  = "NVL2" "(" expr1 "," expr2 "," expr3 ")";

octet_length
  = "OCTET_LENGTH" "(" string ")";

percent_rank
  = "PERCENT_RANK" "(" ")" over_clause;

percentile_cont
  = "PERCENTILE_CONT" "(" expr ")" "WITHIN" "GROUP" "(" "ORDER" "BY" order_expr [ ( "ASC" | "DESC" ) ] ")" [ over_clause ];

percentile_disc
  = "PERCENTILE_DISC" "(" expr ")" "WITHIN" "GROUP" "(" "ORDER" "BY" order_expr [ ( "ASC" | "DESC" ) ] ")" [ over_clause ];

pi
  = "PI" "(" ")";

position
  = "POSITION" "(" search_string "IN" string ")";

posix_time
  = "POSIX_TIME" "(" [datetime] ")";

power
  = "POWER" "(" base "," exponent ")";

radians
  = "RADIANS" "(" n ")";

random
  = ("RANDOM" | "RAND") "(" [min "," max] ")";

rank
  = "RANK" "(" ")" over_clause;

ratio_to_report
  = "RATIO_TO_REPORT" "(" expr ")" over_clause;

regexp_instr
  = "REGEXP_INSTR" "(" string "," pattern;

regexp_instr_2
  = ["," position ["," occurence ["," return_opt]]] ")";

regexp_count
  = "REGEXP_COUNT" "(" string "," pattern ["," start_position ] ")";

regexp_replace
  = "REGEXP_REPLACE" "(" string "," pattern;

regexp_replace_2
  = ["," replace_string [","position ["," occurrence]]] ")";

regexp_substr
  =  "REGEXP_SUBSTR"    "(" string ","  pattern; 

regexp_substr_2
  =  [","position ["," occurrence]] ")"; 

regr_functions
  = ( "REGR_AVGX" | "REGR_AVGY" | "REGR_COUNT" | "REGR_INTERCEPT" | "REGR_R2" | "REGR_SLOPE" | "REGR_SXX" | "REGR_SXY" | "REGR_SYY" ) "(" expr1 "," expr2 ")" [ over_clause ];

repeat
  = "REPEAT" "(" string "," n ")";

replace
  = "REPLACE" "(" string "," search_string ["," replace_string] ")";

reverse
  = "REVERSE" "(" string ")";

right  
  = "RIGHT"  "(" string "," length ")" ;

round_datetime
  = "ROUND" "(" date ["," format] ")";

round_number
  = "ROUND" "(" n [ "," integer ] ")";

row_number
  = "ROW_NUMBER" "(" ")" "OVER" "(" [ partition_clause ] [ order_clause ] ")";

rowid
  = [ [ schema "." ] table "." ] "ROWID";

rpad
  = "RPAD" "(" string "," n [ "," padding ]")";

rtrim
  = "RTRIM" "(" string ["," trim_chars ] ")";

scope_user
  = "SCOPE_USER";

second1
  = "SECOND" "(" datetime [ "," precision ] ")";

seconds_between
  = "SECONDS_BETWEEN" "(" timestamp1 "," timestamp2 ")";

sessiontimezone
  = "SESSIONTIMEZONE";

session_parameter
  = "SESSION_PARAMETER" "(" session_id "," parameter_name ")";

sign
  = "SIGN" "(" n ")";

sin
  = "SIN" "(" n ")";

sinh
  = "SINH" "(" n ")";

some
  = "SOME" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

soundex
  = "SOUNDEX" "(" string ")";

space
  = "SPACE" "(" integer ")";


spatial_1
  = ("ST_AREA" | "ST_BOUNDARY" | "ST_BUFFER" | "ST_CENTROID" | "ST_CONTAINS" | "ST_CONVEXHULL" | "ST_CROSSES" | "ST_DIFFERENCE" | "ST_DIMENSION" | "ST_DISJOINT" | "ST_DISTANCE" | "ST_ENDPOINT") "(" args ")";

spatial_2
  = ("ST_ENVELOPE" | "ST_EQUALS" | "ST_EXTERIORRING" | "ST_FORCE2D" | "ST_GEOMETRYN" | "ST_GEOMETRYTYPE" | "ST_INTERIORRINGN" | "ST_INTERSECTION" | "ST_INTERSECTS" | "ST_ISCLOSED" | "ST_ISEMPTY" | "ST_ISRING" | "ST_ISSIMPLE") "(" args ")";

spatial_3
  = ("ST_LENGTH" | "ST_NUMGEOMETRIES" | "ST_NUMINTERIORRINGS" | "ST_NUMPOINTS" | "ST_OVERLAPS" | "ST_SETSRID" | "ST_POINTN" | "ST_STARTPOINT" | "ST_SYMDIFFERENCE" | "ST_TOUCHES" | "ST_TRANSFORM" | "ST_UNION" | "ST_WITHIN" | "ST_X" | "ST_Y") "(" args ")";

sqrt
  = "SQRT" "(" n ")";

substr
  =  "SUBSTR"    "(" string ","  position [ "," length ] ")" 
   | "SUBSTRING" "(" string "FROM" position [ "FOR" length ] ")";

stddev
  = "STDDEV" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

stddev_pop
  = "STDDEV_POP" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

stddev_samp
  = "STDDEV_SAMP" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

sum
  = "SUM" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

sys_guid
  = "SYS_GUID" "(" ")";

sys_connect_by_path
  = "SYS_CONNECT_BY_PATH" "(" expr "," char ")";

sysdate
  = "SYSDATE";

systimestamp
  = "SYSTIMESTAMP" [ "(" [ precision ] ")" ];

tan
  = "TAN" "(" n ")";

tanh
  = "TANH" "(" n ")";

to_char_datetime
  = "TO_CHAR" "(" (( (datetime) ["," format ["," "'" nlsparam "'"] ]) | interval) ")";

to_char_number
  = "TO_CHAR" "(" number ["," format ] ")";

to_date
  = "TO_DATE" "(" string ["," format ] ")";

to_dsinterval_1
  = "TO_DSINTERVAL" "(" string ")";

to_number
  = "TO_NUMBER" "(" string ["," format ] ")";

to_timestamp
  = "TO_TIMESTAMP" "(" string ["," format ] ")";

to_yminterval
  = "TO_YMINTERVAL" "(" string ")";

translate
  = "TRANSLATE" "(" expr "," from_string "," to_string ")";

trim
  = "TRIM" "(" string [ "," trim_string ] ")";

trim_2
  = "TRIM" "("[ "LEADING" | "TRAILING" | "BOTH" ] [ trim_string "FROM" ] string ")";

trunc_datetime
  = ("TRUNC" | "TRUNCATE") "(" date ["," format ] ")";

trunc_number
  = ("TRUNC" | "TRUNCATE") "(" n ["," integer ] ")";

typeof
  = "TYPEOF" "(" expr ")";

ucase
  = "UCASE" "(" string ")";

unicodechr
  = "UNICODECHR" "(" n ")";

upper
  = "UPPER" "(" string ")";

user
  = "USER";

value2proc
 = "VALUE2PROC" "(" expr ")";

variance
  = "VARIANCE" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

var_pop
  = "VAR_POP" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

var_samp
  = "VAR_SAMP" "(" [ ( "DISTINCT" | "ALL" ) ] expr ")" [ over_clause ];

week
  = "WEEK" "(" date ")";

year1
  = "YEAR" "(" date ")";

years_between
  = "YEARS_BETWEEN" "(" (datetime1) "," (datetime2) ")";

zeroifnull
  = "ZEROIFNULL" "(" number ")";

json_value_1
  = "JSON_VALUE" "(" json_expr [ json_input_clause ] "," json_path_expr [ "RETURNING" data_type ];

json_value_2
  = [ ("ERROR" | "NULL" | "DEFAULT" expr) "ON" "EMPTY" ] [ ("ERROR" | "NULL" | "DEFAULT" expr) "ON" "ERROR" ] ")";

json_extract_1
  = "JSON_EXTRACT" "(" json_expr [ json_input_clause ] "," json_path_expr / ","  ["," "'$.error()'"] ")";

json_extract_2
  = "EMITS" "(" ( column_name data_type) / "," ")";

width_bucket
  = "WIDTH_BUCKET" "(" operand "," bound1 "," bound2 "," bucket_count ")";
```

---

## Predicates & conditions

<sub>source: `diagrams/predicates.bnf`</sub>

```ebnf
comparison_predicates
  = expr1 ("=" | "!=" | "<>" | "^=" | "<" | "<=" | ">" | ">=" ) expr2;

compound_predicates
  = (condition ("AND" | "OR") condition) | "NOT" condition;

between_predicate
  = expr1 [ "NOT" ] "BETWEEN" [ "ASYMMETRIC" | "SYMMETRIC" ] expr2 "AND" expr3;

exists_predicate
  =  "EXISTS" "(" subquery ")";

isnull_predicate
  = expr "IS" [ "NOT" ] "NULL";

regexp_like_predicate
  = string [ "NOT" ] "REGEXP_LIKE" reg_expr;

like_predicate
  = string [ "NOT" ] "LIKE" pattern [ "ESCAPE" esc_char ];

in_predicate
  = expr ["NOT"] "IN" "(" ((expr / ",") | subquery) ")";

json_predicate_1
  = expr [ json_input_clause ] "IS" [ "NOT" ] "JSON" [ ("VALUE" | "ARRAY" | "OBJECT" | "SCALAR") ] ;

json_predicate_2
  = [ ("WITH" | "WITHOUT") "UNIQUE" [ "KEYS"] ];

json_input_clause
  = "FORMAT" "JSON" [ "ENCODING" "UTF8" ];
```

---

## Literals

<sub>source: `diagrams/literale.bnf`</sub>

```ebnf
integer_literal
      = [ "+" | "-" ] digit+;

decimal_literal
      = [ "+" | "-" ] ((digit+ ["." {digit} ]) | ("." digit+));

double_literal
      = decimal_literal ["E" ["+" | "-"] digit+] ;      

boolean_literal
      =  "TRUE" | "FALSE" | "UNKNOWN";

date_literal
      = "DATE" string;

timestamp_literal
      = "TIMESTAMP" string;

interval_ym_literal_1
      = "INTERVAL" (( "'" int "'" "YEAR" ["(" precision ")"]) | ("'" int "'" "MONTH" ["(" precision ")"] ) | ( "'" int "-" int "'" "YEAR" ["(" precision ")"] "TO" "MONTH"));

interval_ds_literal_1
      = "INTERVAL" "'" ((int) | (int time_expr) | (time_expr)) "'";

interval_ds_literal_2
      = (("DAY" | "HOUR" | "MINUTE") ["(" precision ")"]) | ("SECOND" ["(" precision ["," fractional_precision] ")"] );

interval_ds_literal_3
      = ["TO" ("HOUR" | "MINUTE" | ("SECOND" ["(" fractional_precision ")"]))];

string_literal
      = "'"  {character}  "'";

null_literal
      = "NULL";
```

---

## Data types

<sub>source: `diagrams/datentypen.bnf`</sub>

```ebnf
string_datentyp
  = ("CHAR" | "VARCHAR") "(" int ["CHAR"] ")" [["CHARACTER" "SET"] ("ASCII" | "UTF8")];   

```

---

## Miscellaneous (expressions, identifiers, comments, hints)

<sub>source: `diagrams/sonstige.bnf`</sub>

```ebnf
  commit_statement
        = "COMMIT" [ "WORK" ];

  rollback_statement
        = "ROLLBACK" [ "WORK" ];

  execute_script_statement
        = "EXECUTE" "SCRIPT" script ["(" [ script_param / "," ] ")" ];
  
  execute_script_statement_2
        = ["WITH" "OUTPUT"];

  script_param
        = expr | ("ARRAY" "(" expr / "," ")");

  open_schema_statement
        = "OPEN" "SCHEMA" schema;

  close_schema_statement
        = "CLOSE" "SCHEMA";

  kill_statement
        = "KILL" (("SESSION" (session_id | "CURRENT_SESSION" )) | ("STATEMENT" [stmt_id] "IN" "SESSION" session_id [message]));

  msg_clause
        = "WITH" "MESSAGE" string;

  alter_session_statement
        = "ALTER" "SESSION" "SET" param "=" value;

  alter_system_statement
        = "ALTER" "SYSTEM" "SET" param "=" value;

  enforce_index_statement
        = "ENFORCE" "INDEX" index "ON" table ( "(" column / "," ")" );

  drop_index_statement
        = "DROP" "INDEX" index "ON" table;

  enforce_zonemap_statement
        = "ENFORCE" "ZONEMAP" "ON" table "(" column ")";

  drop_zonemap_statement
        = "DROP" "ZONEMAP" "ON" table "(" column ")";

  describe_statement
        = ("DESCRIBE" | "DESC") ["FULL"] object_name;

  explain_virtual_statement
        = "EXPLAIN" "VIRTUAL" subquery;

  recompress_statement
        = "RECOMPRESS" ( ("TABLE" table [ "(" column / "," ")" ] ) | "TABLES" table / "," | "SCHEMA" schema | "SCHEMAS" schema / "," | "DATABASE") ["ENFORCE"];
  
  reorganize_statement
        = "REORGANIZE" ("TABLE" table | "TABLES" table / "," | "SCHEMA" schema | "SCHEMAS" schema / "," | "DATABASE") ["ENFORCE"];
 
  truncate_audit_statement
        = "TRUNCATE" "AUDIT" "LOGS" ["KEEP" (("LAST" ("DAY" | "MONTH" | "YEAR")) | ("FROM" datetime))];

  transfer_statement1
        = "TRANSFER" [transfer_options] source "TO" target; 

  transfer_statement2
        = ["WITH" column_type_list | "WITH_FILE" filename];

  transfer_options
        = ((("APPEND" | "REPLACE") | ("SKIP" "(" offset ")") | ("FIELD_SEPARATOR" "(" sep ")") | ("FIELD_DELIMITER" "(" del ")") | ("ROW_SEPARATOR" "(" ("LF" | "CR" | "CRLF" | "NONE") ")") | "CHECK"))+;

  flush_statistics_statement  
        = "FLUSH" "STATISTICS";

  preload_statement
        = "PRELOAD" ( ("TABLE" table [ "(" column / "," ")" ] ) | "TABLES" table / "," | "SCHEMA" schema | "SCHEMAS" schema / "," | "DATABASE"); 

  create_consumer_group_statement
        = "CREATE" "CONSUMER" "GROUP" identifier "WITH" (( "CPU_WEIGHT" | "PRECEDENCE" ) "=" int | ( "GROUP_TEMP_DB_RAM_LIMIT" | "USER_TEMP_DB_RAM_LIMIT" | "SESSION_TEMP_DB_RAM_LIMIT" ) "=" memory_size | "QUERY_TIMEOUT" "=" time_in_seconds | "IDLE_TIMEOUT" "=" time_in_seconds ) / ",";

  drop_consumer_group_statement
        = "DROP" "CONSUMER" "GROUP" identifier;

  alter_consumer_group_statement
        = "ALTER" "CONSUMER" "GROUP" identifier "SET" (( "CPU_WEIGHT" | "PRECEDENCE" ) "=" int | ( "GROUP_TEMP_DB_RAM_LIMIT" | "USER_TEMP_DB_RAM_LIMIT" | "SESSION_TEMP_DB_RAM_LIMIT" ) "=" memory_size | "QUERY_TIMEOUT" "=" time_in_seconds | "IDLE_TIMEOUT" "=" time_in_seconds ) / ",";
  
  memory_size
        = ( int | ( "'" int [ "M" | "G" | "T" ] "'" ) | "'" "OFF" "'");

  impersonate_statement
        = "IMPERSONATE" user;

  control_move_session_statement_1
        = "CONTROL" "MOVE" (("SESSION" session_id / ",") | ("ALL" "SESSIONS" "FROM" (cluster_name|cluster_uid))) "TO" (cluster_name|cluster_uid);

  control_move_session_statement_2
        = ["WAIT" "TIMEOUT" timeout_in_seconds] ["FORCE"];

```
