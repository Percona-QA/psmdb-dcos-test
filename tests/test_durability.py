#/usr/bin/env python3
import pytest
from pymongo import MongoClient
from config.parse_config import DCOSTestGeneral

config = DCOSTestGeneral()

def test_prepare_data(check_replicaset_health):
    assert check_replicaset_health
