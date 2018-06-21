#/usr/bin/env python3
import pytest
from config.parse_config import DCOSTestGeneral

config = DCOSTestGeneral()

def func(x):
    return x + 1

def test_answer():
    assert func(3) == 5

def test_config():
    assert config.DCOS['master'] == "master_address"
