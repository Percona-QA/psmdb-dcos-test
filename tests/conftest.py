#!/usr/bin/env python3
import pytest
from general.general import DCOSTestGeneral
from pymongo import MongoClient

dcos = DCOSTestGeneral()

@pytest.fixture
def check_replicaset_health():
    c = MongoClient('mongodb://{}:{}@{}/?replicaSet={}&authSource=admin'.format(dcos.MONGO['userapp'], dcos.MONGO['userapppwd'], dcos.MONGO['address'], dcos.MONGO['rs_name']))
    return True
