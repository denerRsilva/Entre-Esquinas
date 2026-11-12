// Optional fast runner for the migrated rules; Godot itself does not need Node.js.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const rules = require('../simulacao/restaurant-core.js');
const legacy = require('./regras/restaurant-core-0.12.0.cjs');
for (const name of ['arrivals', 'service-hours']) {
  const source = fs.readFileSync(path.join(__dirname, 'regras', `${name}.test.cjs`), 'utf8');
  new Function('require', source)(id => id.includes('assert') ? assert : id.includes('legacy') ? legacy : rules);
}

require('./maos.test.cjs');



require('./cadeiras.test.cjs');

require('./maos-migracao.test.cjs');

require('./estante-panelas.test.cjs');

require("./taverna-compacta.test.cjs");
