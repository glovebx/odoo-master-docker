#!/usr/bin/python

from configparser import ConfigParser
import psycopg2

def config(filename='database.ini', section='postgresql'):
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)

    # get section, default to postgresql
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception('Section {0} not found in the {1} file'.format(section, filename))

    return db

def verify(cur):
    cur.execute("select id, name from ir_attachment where res_model='ir.ui.view' and ((name like '%.assets_%' and name like '%.css') or (name like '%.assets_%' and name like '%.js')) ")
    name_list = cur.fetchall()
    print(name_list)

def connect():
    """ Connect to the PostgreSQL database server """
    conn = None
    try:
        # read connection parameters
        params = config()

        # connect to the PostgreSQL server
        print('Connecting to the PostgreSQL database...')
        conn = psycopg2.connect(**params)

        # create a cursor
        cur = conn.cursor()
        
        print('Start purging assets files...')

        verify(cur)

        # cur.execute("delete from ir_attachment where res_model='ir.ui.view' and ((name like '%.assets_%' and name like '%.css') or (name like '%.assets_%' and name like '%.js')) ")
        cur.execute("DELETE FROM ir_attachment WHERE datas_fname SIMILAR TO '%.(js|css)'")
        cur.execute("DELETE FROM ir_attachment WHERE name='web_icon_data'")

        verify(cur)

        conn.commit()

        print('End purging assets files.')

    # execute a statement
        print('PostgreSQL database version:')
        cur.execute('SELECT version()')

        # display the PostgreSQL database server version
        db_version = cur.fetchone()
        print(db_version)
       
    # close the communication with the PostgreSQL
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()
            print('Database connection closed.')


if __name__ == '__main__':
    connect()