#!/bin/bash
gunicorn app:"prod()" -w 1 --threads 1 -b 0.0.0.0:8212