import os
import json
from datetime import datetime
from typing import Optional, Iterable, Dict, Set

import psycopg2
import psycopg2.extras


# ---- DB connection params ----
DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

# Global connection (reused across Lambda invocations if container is reused)
_db_conn = None

def get_db_connection():
    global _db_conn
    if _db_conn is None or _db_conn.closed:
        _db_conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
        )
        _db_conn.autocommit = False  # we will commit manually
    return _db_conn

def table_exists(conn, table_name: str, schema: str = "public") -> bool:
    """
    Return True if table (schema.table_name) exists, else False.
    """
    query = """
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = %s
          AND table_name = %s
        LIMIT 1;
    """
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute(query, (schema, table_name))
        return cur.fetchone() is not None

def get_existing_columns(conn, table_name: str, schema: str = "public") -> Set[str]:
    """
    Return a set of existing column names for (schema.table_name).
    """
    query = """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = %s
          AND table_name = %s;
    """
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        cur.execute(query, (schema, table_name))
        rows = cur.fetchall()
    return {r[0] for r in rows}

def createTable(conn, table_name: str, schema_spec: Dict, schema: str = "public"):
    print("creating table")
    createtablestring = "CREATE TABLE IF NOT EXISTS "
    table_definition = []
    for k, v in schema_spec.items():
        table_definition.append(k + " " + v)
    query = createtablestring + schema + "." +table_name + "( " + ", ".join(table_definition) + " );"
    print("create table query")
    print(query)

    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    cursor.execute(query)
    conn.commit()

def ensure_table_schema(
    conn,
    table_name: str,
    schema_spec: Dict,
    schema: str = "public",
) -> None:
    """
    Ensure that a table exists and has all columns defined in schema_spec.
    
    schema_spec structure:
    {
      "tablename": {
        "col1": "TYPE ...",
        "col2": "TYPE ...",
        ...
      }
    }
    """
    columns_spec = schema_spec.keys()

    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        # 1. Find existing columns
        existing_cols = get_existing_columns(conn, table_name)

        # 2. Add any missing columns
        for col_name in columns_spec:
            if col_name in existing_cols:
                continue
            col_def = schema_spec.get(col_name)

            # Build ALTER TABLE statement
            alter_sql = f'ALTER TABLE "{schema}"."{table_name}" ADD COLUMN {col_name} {col_def};'
            print(f"[schema-evolve] Adding column: {schema}.{table_name}.{col_name} {col_def}")
            cur.execute(alter_sql)

    conn.commit()

def ensure_all_tables(
    schema_file_path: str = "schema.json",
    schema: str = "public",
) -> None:
    """
    For each table in table_names, ensure it exists and has all required columns.
    Table definitions are loaded from schema_file_path.
    """
    with open(schema_file_path, "r", encoding="utf-8") as f:
        all_specs = json.load(f)

    conn = get_db_connection()

    for table_name in all_specs.keys():
        spec = all_specs.get(table_name)
        if spec is None:
            raise ValueError(f"No schema spec found for table '{table_name}' in {schema_file_path}")
        createTable(conn, table_name, spec, schema)
        # if table_exists(conn, table_name, schema=schema):
        ensure_table_schema(conn, table_name, spec, schema=schema)

def closeDB():
    conn = get_db_connection()
    conn.close()

ensure_all_tables()