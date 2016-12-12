#!/usr/bin/env python

""" This script update a distribution list based on a local source (SQL or binary)
This ensure my newsletters are received by all the intended recipients.
"""

import sys
import subprocess
from argparse import ArgumentParser
from getpass import getpass
try:
    import ldap
    import ldap.filter
except ImportError:
    print("Dependencies not met. Please install python-ldap package first.")
    sys.exit(1)


class SQL:
    def __init__(self, dbms, host, user, db):
        self.typedb = dbms
        self.host = host
        self.user = user
        self.passwd = getpass("{0} password for user {1} : ".format(self.typedb.title(), self.user))
        self.db = db

    def filter_cursor(self, rows):
        new_rows = []
        for r in rows:
           if isinstance(r, tuple):
               new_rows.append(r[0])
        return new_rows

    def extract(self, command):
        if self.typedb == 'mysql':
            try:
                import mysql.connector
            except ImportError:
                print("Dependencies not met. Please run 'pip install mysql-connector' first.")
                sys.exit(1)
            dbms_connection = mysql.connector.connect(host=self.host, user=self.user, password=self.passwd,
                                                      database=self.db)
        elif self.typedb == 'psql':
            import psycopg2
            dbms_connection = psycopg2.connect(host=self.host, user=self.user, password=self.passwd, database=self.db)
        else:
            print("Unknown DBMS {0}".format(self.typedb))
            sys.exit(1)

#        import pdb;pdb.set_trace()
        cursor = dbms_connection.cursor()
        cursor.execute(command)
        rows = cursor.fetchall()
        dbms_connection.close()
        rows = self.filter_cursor(rows)
        return rows


# End of Class


# Applications extractors
def extract_testrail_admins(host, user, db):
    # Mysql execute a simple select to gather all TestRail Admins
    command = "SELECT email from users where is_admin=1 AND is_active=1;"
    dbms = SQL('mysql', host, user, db)
    rows = dbms.extract(command)
    return rows


def extract_gitlab():
    # Gitlab maintained by UPS is using omnibus package and thus doesn't open any port for psql,
    # command needs to be launched by binary gitlab-psql
    command = "'select email from users;'"
    rows = subprocess.Popen("/bin/gitlab-psql -qt gitlabhq_production -c {0}".format(command), shell=True,
                 stdout=subprocess.PIPE).stdout.read().split()
    # Filter non-emails
    rows = [r for r in rows if '@' in r]
    return rows


def ldapconnect(LDAP_SERVER):
    BIND_DN = args.bind
    BIND_PASS = getpass("Enter LDAP password for user {0} : ".format(BIND_DN))
    try:
        ldap_connection = ldap.initialize(LDAP_SERVER)
        ldap_connection.protocol_version = 3
        ldap_connection.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, 0)
        ldap_connection.set_option(ldap.OPT_REFERRALS, 0)
        ldap_connection.simple_bind_s(BIND_DN,BIND_PASS)
        return ldap_connection
    except ldap.LDAPError as e:
        print("Error connecting to LDAP server: {0}".format(e))
        sys.exit(1)


def parse_args():
    parser = ArgumentParser()
    parser.add_argument("-u","--user", default="root", help="Username to use for connection to SGBD.")
    parser.add_argument("--host", default="localhost", help="Host of SGBD. Localhost by default")
    parser.add_argument("-d","--database", help="Database to connect to")
    parser.add_argument("-p","--port", type=str, help="Port of SGBD")
    parser.add_argument("-t","--type", required=True, choices=['testrail','gitlab'], help="Type of Application to extract users from.")
    parser.add_argument("-b", "--bind", required=True, help="Ldap bind user to connect to Active Directory")
    parser.add_argument("-a", "--ad", required=True, help="Active Directory server. ie: ldaps://dc.local:636")
    parser.add_argument("-g", "--group", required=True, help="Distribution List to update.")
    parser.add_argument("-s", "--basedn", required=True, help="Base DN to search.")
    args = parser.parse_args()
    return args


if __name__ == '__main__':

    args = parse_args()
    if args.type == 'gitlab':
        rows = extract_gitlab()
    elif args.type == 'testrail':
        if 'db' not in locals().keys() or not args.db:
            print('No database specified for testrail, using \'testrail\' by default.')
            args.db = 'testrail'
        rows = extract_testrail_admins(args.host, args.user, args.db)

    # Once we get a list of all elements, we proceed with LDAP part.
    ldap_connection = ldapconnect(args.ad)
    for r in rows:
        mail = ldap.filter.filter_format('(mail=%s)',[r])
        admin_dn = ldap_connection.search_s(args.basedn, ldap.SCOPE_SUBTREE, mail, attrlist=['distinguishedName'])
        # It will print  ForestDnsZones if the user hasn't been found
        if admin_dn[0][0] != None:
          add_member = [(ldap.MOD_ADD, 'member', admin_dn[0][1]['distinguishedName'][0])]
          try:
            ldap_connection.modify_s(args.group, add_member)
            print("Added user {0}".format(r))
          except ldap.ALREADY_EXISTS:
            print("User {0} was already in the LDAP group".format(r))
        else:
          print("User {0} not found in the Directory".format(r))

    print("successful, closing ldap socket...")
    ldap_connection.unbind_s()


# vim: bg=dark ts=4 expandtab

