#!/usr/bin/env python3
import argparse
import psycopg2
import sys
import time


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--db_host', required=True)
    arg_parser.add_argument('--db_port', required=True)
    arg_parser.add_argument('--db_user', required=True)
    arg_parser.add_argument('--db_password', required=True)
    arg_parser.add_argument('--timeout', type=int, default=5)

    args = arg_parser.parse_args()

    timeout = args.timeout
    start_time = time.time()
    last_error = None

    while True:
        try:
            conn = psycopg2.connect(
                user=args.db_user,
                host=args.db_host,
                port=args.db_port,
                password=args.db_password,
                dbname='postgres'
            )
            print("Database connection successful!")
            conn.close()
            break
        except psycopg2.OperationalError as e:
            last_error = e
            print(f"Connection failed: {e}. Retrying...")

        if (time.time() - start_time) > timeout:
            print(f"Failed to connect to the database after {timeout} seconds.")
            if last_error:
                print(f"Last error: {last_error}")
            break

        time.sleep(1)