#!/usr/bin/env python3
import pytest
from config.parse_config import DCOSTestGeneral
from pymongo import MongoClient

config = DCOSTestGeneral()

@pytest.fixture
def check_replicaset_health():
    c = MongoClient(config.MONGO['node1_host'], int(config.MONGO['node1_port']))
    return True
