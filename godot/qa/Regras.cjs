// Optional fast runner for the migrated rules; Godot itself does not need Node.js.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const rules = require('../simulacao/restaurant-core.js');
const legacy = require('./regras/restaurant-core-0.12.0.cjs');
for (const name of ['arrivals', 'calendar-reputation', 'patience', 'service-hours', 'waiter-orders']) {
  const source = fs.readFileSync(path.join(__dirname, 'regras', `${name}.test.cjs`), 'utf8');
  new Function('require', source)(id => id.includes('assert') ? assert : id.includes('legacy') ? legacy : rules);
}

require('./fluxo-cozinha.test.cjs');

require('./inventario.test.cjs');

require('./cadeiras.test.cjs');
