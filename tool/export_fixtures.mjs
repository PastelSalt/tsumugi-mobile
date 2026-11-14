// One-off export from the website project (never run at app build time).
//   node tool/export_fixtures.mjs
// Writes:
//   assets/data/fixtures.json           the sample data, exactly as the website holds it
//   test/fixtures/web_parity.json       values computed by the website's own selectors and parser,
//                                       so Dart tests can assert the port matches the website.
// Requires the website's node_modules (it borrows its rolldown to bundle the ES modules).
import { createRequire } from 'node:module'
import { mkdirSync, writeFileSync, mkdtempSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { pathToFileURL } from 'node:url'

const web = resolve('..', 'CTINASSL_Activity', 'client')
const require = createRequire(join(web, 'package.json'))
const { rolldown } = require('rolldown')
const data = join(web, 'src', 'pages', 'workspace', 'data')
const quick = join(web, 'src', 'pages', 'workspace', 'quickadd')

const entry = `
import * as fx from ${JSON.stringify(join(data, 'fixtures.js'))}
import * as sel from ${JSON.stringify(join(data, 'selectors.js'))}
import { data as storeData } from ${JSON.stringify(join(data, 'store.js'))}
import { parseQuickAdd } from ${JSON.stringify(join(quick, 'parse.js'))}
import { templates } from ${JSON.stringify(join(data, 'templates.js'))}
export { fx, sel, storeData, parseQuickAdd, templates }
`
const dir = mkdtempSync(join(tmpdir(), 'tsumugi-export-'))
const entryFile = join(dir, 'entry.mjs')
writeFileSync(entryFile, entry)
const bundle = await rolldown({ input: entryFile, platform: 'node', cwd: web, logLevel: 'silent' })
const { output } = await bundle.generate({ format: 'esm' })
const file = join(dir, 'bundle.mjs')
writeFileSync(file, output[0].code)
const { fx, sel, storeData, parseQuickAdd, templates } = await import(pathToFileURL(file).href)

const fixtures = {
  workspace: fx.workspace, projects: fx.projects, milestones: fx.milestones, tasks: fx.tasks,
  requirements: fx.requirements, files: fx.files, changes: fx.changes, templates,
}
mkdirSync('assets/data', { recursive: true })
writeFileSync('assets/data/fixtures.json', JSON.stringify(fixtures, null, 1))

const ids = (list) => list.map((x) => x.id)
const d = storeData()
const projectIds = d.projects.map((p) => p.id)
const parity = {
  counts: Object.fromEntries(Object.entries(fixtures).filter(([k]) => Array.isArray(fixtures[k]) && k !== 'templates').map(([k, v]) => [k, v.length])),
  figures: sel.figures(),
  todayList: Object.fromEntries(Object.entries(sel.todayList()).map(([k, v]) => [k, ids(v)])),
  todayListGarden: Object.fromEntries(Object.entries(sel.todayList('project-garden')).map(([k, v]) => [k, ids(v)])),
  upNext7: sel.upNext(7).map((i) => `${i.kind}:${i.record.id}`),
  upNext30: sel.upNext(30).map((i) => `${i.kind}:${i.record.id}`),
  recentProjects: ids(sel.recentProjects(4)),
  recents: sel.recents(6).map((r) => `${r.type}:${r.id}`),
  activeProjects: ids(sel.activeProjects()),
  projectProgress: Object.fromEntries(projectIds.map((id) => [id, sel.projectProgress(id)])),
  projectHealth: Object.fromEntries(projectIds.map((id) => [id, sel.projectHealth(id)])),
  projectCounts: Object.fromEntries(projectIds.map((id) => [id, sel.projectCounts(id)])),
  nextMilestone: Object.fromEntries(projectIds.map((id) => [id, sel.nextMilestone(id)?.id ?? null])),
  milestoneState: Object.fromEntries(d.milestones.map((m) => [m.id, sel.milestoneState(m)])),
  milestoneProgress: Object.fromEntries(d.milestones.map((m) => [m.id, sel.milestoneProgress(m.id)])),
  coverageAll: sel.coverage('all'),
  coverageByProject: Object.fromEntries(projectIds.map((id) => [id, sel.coverage(id)])),
  requirementGaps: Object.fromEntries(d.requirements.map((r) => { const l = sel.requirementLinks(r); return [r.id, { gaps: l.gaps, tasks: ids(l.tasks), files: ids(l.files), changes: ids(l.changes), milestone: l.milestone?.id ?? null }] })),
  criteria: Object.fromEntries(d.requirements.map((r) => [r.id, sel.criteriaProgress(r)])),
  overdue: sel.overdueRecords().map((o) => `${o.type}:${o.record.id}`),
  isFinalFile: Object.fromEntries(d.files.map((f) => [f.id, sel.isFinalFile(f)])),
  recordHref: { project: sel.recordHref('Project', 'project-garden'), task: sel.recordHref('Task', 't1'), docFile: sel.recordHref('File', 'd-brief'), plainFile: sel.recordHref('File', 'a-cover'), requirement: sel.recordHref('Requirement', 'REQ-001'), milestone: sel.recordHref('Milestone', 'm1'), change: sel.recordHref('Change', 'r1') },
  parse: [
    'Proof chapter one #garden tomorrow !',
    'Write notes today',
    'Call mentor fri',
    'Plan thu !high',
    'Review wed #api',
    'Just a title',
    'Draft intro #zzz mon',
    '  spaced   out   text  ',
  ].map((text) => ({ text, fallback: 'project-garden', result: parseQuickAdd(text, 'project-garden') })),
}
mkdirSync('test/fixtures', { recursive: true })
writeFileSync('test/fixtures/web_parity.json', JSON.stringify(parity, null, 1))
console.log('fixtures.json and web_parity.json written', parity.counts, parity.figures)
