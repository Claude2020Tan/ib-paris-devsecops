#!/bin/bash
#comment
sudo docker ps | grep -qi "webapp"
curl http://localhost | grep -iq "Dimension"