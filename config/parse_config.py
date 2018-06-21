#!/usr/bin/env python3
import configparser
import os
import logging
logger = logging.getLogger(__name__)

class DCOSTestGeneral:

    def __init__(self, config=os.path.dirname(os.path.abspath(__file__)) + '/config.ini'):

        if os.path.isfile(config):
            conf = configparser.ConfigParser()
            conf.read(config)

            self.DCOS = conf['dcos']
            self.AWS = conf['aws']
            self.MONGO = conf['mongo']

        else:
            logger.critical("Missing config file: " + config)
