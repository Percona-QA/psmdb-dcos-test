#/usr/bin/env python3
import pytest
from general.general import DCOSTestGeneral

dcos = DCOSTestGeneral()

def func(x):
    return x + 1

def test_answer():
    assert func(3) == 5

def test_config():
    assert dcos.DCOS['master'] == "master_address"
