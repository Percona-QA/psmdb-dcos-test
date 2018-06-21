#/usr/bin/env python3
import pytest
from pymongo import MongoClient
from general.general import DCOSTestGeneral

dcos = DCOSTestGeneral()

def test_prepare(check_replicaset_health):
    assert check_replicaset_health
