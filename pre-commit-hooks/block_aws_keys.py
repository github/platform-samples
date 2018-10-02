## This script is still in its early stages, and will morph to include Google, Azure and OpenStack as well
##
from __future__ import print_function
from __future__ import unicode_literals

import argparse
import os

from six.moves import configparser


def get_aws_credential_files_from_env():
    """
    Extract credential file paths from environment variables.
    @:return files:
    @:rtype files: set
    """
    files = set()
    for env_var in ('AWS_CONFIG_FILE', 'AWS_CREDENTIAL_FILE', 'AWS_SHARED_CREDENTIALS_FILE', 'BOTO_CONFIG'):
        if env_var in os.environ:
            files.add(os.environ[env_var])
    return files


def get_aws_secrets_from_env():
    """
    Extract AWS secrets from environment variables.
    @:return keys:
    @:rtype keys: set
    """
    keys = set()
    for env_var in ('AWS_SECRET_ACCESS_KEY', 'AWS_SECURITY_TOKEN', 'AWS_SESSION_TOKEN'):
        if env_var in os.environ:
            keys.add(os.environ[env_var])
    return keys


def get_aws_secrets_from_file(credentials_file):
    """
    Extract AWS secrets from configuration files.

    Read an ini-style configuration file and return a set with all found AWS
    secret access keys.
    @:param credentials_file: The name of the file to check
    @:type credentials_file:
    @:return keys:
    @:rtype keys: set
    """
    aws_credentials_file_path = os.path.expanduser(credentials_file)
    if not os.path.exists(aws_credentials_file_path):
        return set()

    parser = configparser.ConfigParser()
    try:
        parser.read(aws_credentials_file_path)
    except configparser.MissingSectionHeaderError:
        return set()

    keys = set()
    for section in parser.sections():
        for var in ('aws_secret_access_key', 'aws_security_token', 'aws_session_token'):
            try:
                key = parser.get(section, var).strip()
                if key:
                    keys.add(key)
            except configparser.NoOptionError:
                pass
    return keys


def check_file_for_aws_keys(filenames, keys):
    """
    Check if files contain AWS secrets.

    Return a list of all files containing AWS secrets and keys found, with all
    but the first four characters obfuscated to ease debugging.
    @:param filenames:
    @:param keys:
    @:type filenames: list
    @:type keys:
    @:return bad_files: List of files containing forbidden keys
    @:rtype bad_files: list
    """
    bad_files = []

    for filename in filenames:
        with open(filename, 'r') as content:
            text_body = content.read()
            for key in keys:
                # naively match the entire file, low chance of incorrect collision
                if key in text_body:
                    bad_files.append({
                        'filename': filename, 'key': key[:4] + '*' * 28,
                    })
    return bad_files


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', 'filenames', nargs='+', default=None, help='Filenames to validate against')
    parser.add_argument('-c', '--credentials-file', dest='credential_files', action='append',
                        default=['~/.aws/config', '~/.aws/credentials', '/etc/boto.cfg', '~/.boto'],
                        help='Location of additional AWS credential files from which to get secret keys')
    parser.add_argument('-m', '--allow-missing-credentials', dest='allow_missing_credentials', action='store_true',
                        help='Allow hook to pass when no credentials are detected.')
    args = parser.parse_args(argv)

    credential_files = set(args.credential_files)

    # Add the credentials files configured via environment variables to the set
    # of files to to gather AWS secrets from.
    credential_files |= get_aws_credential_files_from_env()

    keys = set()
    for credential_file in credential_files:
        keys |= get_aws_secrets_from_file(credential_file)

    # Secrets might be part of environment variables, so add them to the set of keys.
    keys |= get_aws_secrets_from_env()

    if not keys and args.allow_missing_credentials:
        return 0

    if not keys:
        print('No AWS keys were found in the default credential files or environment variables.')
        print('Please ensure you have the correct setting for --credentials-file')
        return 2

    bad_filenames = check_file_for_aws_keys(args.filenames, keys)
    if bad_filenames:
        for bad_file in bad_filenames:
            print('AWS secret found in {filename}: {key}'.format(**bad_file))
        return 1
    else:
        return 0


if __name__ == '__main__':
    exit(main())
