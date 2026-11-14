// Converts a WOFF 1.0 font (zlib-compressed tables) to a plain TrueType/OpenType file.
// Flutter cannot load WOFF, so the web project's Fredoka files are unpacked once with this script.
// Usage: node tool/woff_to_ttf.mjs <in.woff> <out.ttf>
import { readFileSync, writeFileSync } from 'node:fs'
import { inflateSync } from 'node:zlib'

const [input, output] = process.argv.slice(2)
const buf = readFileSync(input)
if (buf.toString('ascii', 0, 4) !== 'wOFF') throw new Error('Not a WOFF 1.0 file')
const flavor = buf.readUInt32BE(4)
const numTables = buf.readUInt16BE(12)
const tables = []
for (let i = 0; i < numTables; i += 1) {
  const o = 44 + i * 20
  const tag = buf.toString('ascii', o, o + 4)
  const offset = buf.readUInt32BE(o + 4)
  const compLength = buf.readUInt32BE(o + 8)
  const origLength = buf.readUInt32BE(o + 12)
  const checksum = buf.readUInt32BE(o + 16)
  const raw = buf.subarray(offset, offset + compLength)
  tables.push({ tag, checksum, data: compLength < origLength ? inflateSync(raw) : raw })
}
tables.sort((a, b) => (a.tag < b.tag ? -1 : 1))
const pad = (n) => (n + 3) & ~3
let offset = 12 + 16 * numTables
const header = Buffer.alloc(offset)
header.writeUInt32BE(flavor, 0)
header.writeUInt16BE(numTables, 4)
const entrySelector = Math.floor(Math.log2(numTables))
const searchRange = 2 ** entrySelector * 16
header.writeUInt16BE(searchRange, 6)
header.writeUInt16BE(entrySelector, 8)
header.writeUInt16BE(numTables * 16 - searchRange, 10)
const parts = [header]
tables.forEach((t, i) => {
  const o = 12 + i * 16
  header.write(t.tag, o, 'ascii')
  header.writeUInt32BE(t.checksum, o + 4)
  header.writeUInt32BE(offset, o + 8)
  header.writeUInt32BE(t.data.length, o + 12)
  const padded = Buffer.alloc(pad(t.data.length))
  t.data.copy(padded)
  parts.push(padded)
  offset += padded.length
})
writeFileSync(output, Buffer.concat(parts))
console.log(`${input} -> ${output} (${numTables} tables)`)
