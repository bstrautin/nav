import pytest
import os
import re
import shlex
from django import setup
from nav.buildconf import bindir

TESTARGS_PATTERN = re.compile(
    r'^# +-\*-\s*testargs:\s*(?P<args>.*?)\s*(-\*-)?\s*$',
    re.MULTILINE)
NOTEST_PATTERN = re.compile(
    r'^# +-\*-\s*notest\s*(-\*-)?\s*$', re.MULTILINE)


def pytest_configure():
    os.environ['DJANGO_SETTINGS_MODULE'] = 'nav.django.settings'
    setup()


def pytest_generate_tests(metafunc):
    if 'binary' in metafunc.fixturenames:
        binaries = _nav_binary_tests()
        ids = [b[0] for b in binaries]
        metafunc.parametrize("binary", _nav_binary_tests(), ids=ids)

def _nav_binary_tests():
    for binary in _nav_binary_list():
        for args in _scan_testargs(binary):
            if args:
                yield args

def _nav_binary_list():
    files = sorted(os.path.join(bindir, f)
                   for f in os.listdir(bindir)
                   if not _is_excluded(f))
    return (f for f in files if os.path.isfile(f))


def _is_excluded(filename):
    return (filename.endswith('~') or filename.startswith('.') or
            filename.startswith('Makefile'))


def _scan_testargs(filename):
    """
    Scans filename for testargs comments and returns a list of elements
    suitable for invocation of this binary with the given testargs
    """
    contents = open(filename, "rb").read()
    matches = TESTARGS_PATTERN.findall(contents)
    if matches:
        retval = []
        for testargs, _ in matches:
            testargs = shlex.split(testargs)
            retval.append([filename] + testargs)
        return retval
    else:
        matches = NOTEST_PATTERN.search(contents)
        if not matches:
            return [[filename]]
        else:
            return []