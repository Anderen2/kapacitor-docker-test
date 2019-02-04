#!/usr/bin/python

import json, glob, os

checks = {}
for file in glob.glob("/checks/*.json"):
	with open(file, "r") as fd:
		checks.update(json.load(fd))

alerts = []
for file in glob.glob("/alerts/*"):
	with open(file, "r") as fd:
		alerts.append(json.load(fd))


for alert in alerts:
	if not (alert["id"] in checks):
		print("Alert %s not in checks!" % alert["id"])
		print(alert)
		exit(1)

	if alert["level"] != checks[alert["id"]]:
		print("Alert %s failed check (%s != %s)" % (alert["id"], alert["level"], checks[alert["id"]]))
		print(alert)
		exit(2)

	del checks[alert["id"]]

	print("Check passed: %s" % alert["id"])

if len(checks) != 0:
	print("Checks/Alerts not triggered:")
	for check in checks.keys():
		print(check)

	exit(3)