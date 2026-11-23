'use strict';

const assert = require('node:assert/strict');
const {greet} = require('../library/build/greeting.js');
assert.equal(greet('mk'), 'Hello, mk!');
process.stdout.write('PASS: local JSC dependency\n');
