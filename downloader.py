#!/usr/bin/env python

import sys
import os
import json
import hashlib
from urllib2 import urlopen, URLError, HTTPError


BLOCKSIZE = 8192
SEP = '    '


def log(msg, begin='', end='\n', stream='stdout'):
    getattr(sys, stream).write(begin + msg + end)
    getattr(sys, stream).flush()

if len(sys.argv) != 2:
    log("Usage: %s <files.json>" % sys.argv[0], stream='stderr')
    sys.exit(1)

def get_md5(filename):
    try:
        with open(filename, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()
    except IOError:
        pass


try:
    with open(sys.argv[1]) as json_file:
        data = json.load(json_file)

        if data['basedir'] and not os.path.exists(data['basedir']):
            try:
                os.makedirs(data['basedir'])
            except OSError:
                log("Error creating dir %s" % data['basedir'], stream='stderr')
                sys.exit(1)

        for i, _ in enumerate(data['files']):
            if i:
                log('')
            log("%2d. %s" % (i, _['url']))

            if not _['out']:
                _['out'] = os.path.basename(_['url'])
            out = os.path.join(data['basedir'], _['out'])

            if _['md5'] and _['md5'] == get_md5(out):
                log("%s exists and MD5 is OK, nothing to do." % _['out'],
                    begin=SEP)
                continue

            chunks = _['out'].split('/')
            if len(chunks) > 1:
                dir = os.path.join(data['basedir'], '/'.join(chunks[:-1]))
                if not os.path.exists(dir):
                    try:
                        os.makedirs(dir)
                    except OSError:
                        log("Error creating dir %s" % dir, begin=SEP)
                        continue

            try:
                log("Connecting ... ", begin=SEP, end='')
                u = urlopen(_['url'])
            except HTTPError as e:
                log("The server couldn't fulfill the request.")
                log("Error code: %s" % e.code, begin=SEP)
                continue
            except URLError as e:
                log("We failed to reach a server.")
                log("Reason: %s" % e.reason, begin=SEP)
                continue
            else:
                log("OK.")

            h = u.info()
            if 'Content-Length' in h:
                size = int(h['Content-Length'])
            else:
                size = 0

            args = (out, size or '???', '... ' if size else '')
            log("Downloading %s (%s bytes) %s" % args, begin=SEP, end='')

            try:
                with open(out, 'wb') as output_file:
                    count = 0
                    while True:
                        chunk = u.read(BLOCKSIZE)
                        if not chunk:
                            break
                        output_file.write(chunk)
                        count += 1
                        if size:
                            percent = int(count * BLOCKSIZE * 100 / size)
                            if percent > 100:
                                percent = 100
                            log("%2d%% " % percent, end='')
                            if percent < 100:
                                log("\b\b\b\b", end='')
                        else:
                            log('.', end='')
                    log("Done.")

            except IOError, e:
                log(e.strerror)
            else:
                if _['md5'] and _['md5'] == get_md5(out):
                    log("MD5 OK.", begin=SEP)
                else:
                    log("Failed checking MD5.", begin=SEP)

except IOError as e:
    log(e.strerror, stream='stderr')
    sys.exit(1)
