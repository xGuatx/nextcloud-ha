#!/bin/bash

sudo  docker ps --filter name=nextcloud_stack_nextcloud --format "{{ .ID }}"
