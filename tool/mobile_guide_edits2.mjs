// One-off: the remaining address-bar wording in the bundled guide copy.
import { readFileSync, writeFileSync } from 'node:fs'

const file = 'assets/docs/individual-workspace-guide.md'
let s = readFileSync(file, 'utf8')
const missed = []
const swap = (from, to) => {
  if (!s.includes(from)) missed.push(from.slice(0, 60))
  else s = s.replace(from, to)
}
swap('To see this state in the demo, add `?preview=empty` to the address or choose "Empty / first run" in the developer bar.', 'To see this state in the demo, turn on developer tools in Account, then choose "Empty" as the preview state in the account menu.')
swap('- Your view, filters, and selected task are kept in the address bar, so you can bookmark or share a link to exactly what you see.', '- Your view, filters, and selected task are part of the screen’s link, so the app can return you to exactly what you were looking at.')
swap('- The month is kept in the address bar as `?month=2026-11`.', '- The month you are looking at is remembered while you move between tabs.')
swap('Yes. The view, filters, selected record, and calendar month are in the address bar.', 'Inside the app, yes: the view, filters, selected record, and calendar month are part of each screen’s link. Sharing links outside the app is not available in the demo.')
writeFileSync(file, s)
console.log(missed.length ? `Not matched: ${missed.join(' | ')}` : 'applied')
