// One-off: light mobile wording edits to the bundled copy of the website's guide
// (assets/docs/individual-workspace-guide.md). Desktop-only wording (keyboard shortcuts, the left
// rail, the address bar, hover) is replaced; everything else stays as written on the website.
// Prints any edit that did not match so nothing fails silently.
import { readFileSync, writeFileSync } from 'node:fs'

const file = 'assets/docs/individual-workspace-guide.md'
let s = readFileSync(file, 'utf8')
const missed = []
const swap = (from, to) => {
  if (typeof from === 'string' ? !s.includes(from) : !from.test(s)) missed.push(String(from).slice(0, 70))
  else s = s.replace(from, to)
}

swap('in your browser. Nothing is saved', 'on your phone. Nothing is saved')
swap('last until you reload the page.', 'last until you close and reopen the app.')
swap('The left rail (or the bottom bar on a phone) has five destinations:', 'The bottom bar has four destinations, with a round **+** Quick add button in the middle. The fifth, Insights, is in the account menu:')
swap(/Your account menu sits at the bottom of the left rail\. On a phone it is the round button at the top right, and Insights is listed there because the bottom bar has room for only four destinations\./, 'Your account menu is the round button at the top right. It lists Insights because the bottom bar has room for only four destinations.')
swap('### 2.2 The top bar', '### 2.2 The top bar and Home figures')
swap('- **Search or jump to:** opens the command palette (see 2.3).', '- **Search or jump to:** the magnifying-glass button opens the search page (see 2.3).')
swap(/- \*\*Today chip:\*\* the date the demo treats as today\.\n- \*\*Due today and Overdue chips:\*\* counts of open tasks\. Select either to open Tasks\./, '- **Due today and Overdue:** counts of open tasks, shown at the top of Home. Select a task there to open it.')
swap('### 2.3 The command palette', '### 2.3 Search or jump to')
swap('Press **Ctrl+K** (or **Cmd+K** on a Mac), or select the search box in the top bar.', 'Select the magnifying-glass button at the top of any tab.')
swap('- Use the **Up** and **Down** arrow keys to move, **Enter** to open, and **Esc** to close.', '- Tap a result to open it. Use the back button to close the page.')
swap(/### 2\.4 Keyboard shortcuts\n\n[\s\S]*?\n(?=### 2\.5)/, '### 2.4 Buttons and gestures\n\n- **+ (middle of the bottom bar):** open Quick add.\n- **Back button or swipe:** close a sheet or go back.\n- **Drag a sheet up:** show more of a record’s details.\n\n')
swap('Select your name at the bottom of the left rail. The menu holds:', 'Select the round account button at the top right. The menu holds:')
swap('- **Account and preferences:** profile and preferences.', '- **Insights:** the fifth destination.\n- **Account and preferences:** profile and preferences.')
swap('- **Back to landing page** and **Leave demo.**', '- **Back to welcome** and **Leave demo.**')
swap(' Hover over a date to see the exact day.', '')
swap('1. Press **Q**, select **Quick add** in the rail, or use the round **+** button in the phone bar.', '1. Tap the round **+** button in the middle of the bottom bar.')
swap('3. Press **Enter** to add it. A confirmation line appears and the field clears.', '3. Tap **Add task**, or press the keyboard’s done key. A confirmation line appears and the field clears.')
swap('4. Press **Esc** to close.', '4. Tap **Close** to finish.')
swap('Type and press Enter.', 'Type and press the keyboard’s done key.')
swap(/Select a task to open its panel\. On wide screens the panel docks on the right; on smaller screens it slides up from the bottom\./, 'Tap a task to open its details. They slide up from the bottom and can be pulled up to fill the screen.')
swap('Press **Esc** or the close button to dismiss it.', 'Swipe the sheet down, or use the back button, to dismiss it.')
swap('cannot be previewed in the browser', 'cannot be previewed in the app')
swap('- Turn them on from the account menu, from Account, or by adding `?dev` to the address.', '- Turn them on from the account menu or from Account.')
swap('- **Reset sample data:** removes the tasks and projects you added this session.', '- **Reset session data:** removes the tasks and projects you added this session (in Account, under Developer).')
swap('1. Press **Ctrl+K**, type "New project", and press Enter.', '1. Tap the search button, type "New project", and tap the result.')
swap('4. Use **Quick add** (`Q`) with a day word', '4. Use **Quick add** (the **+** button) with a day word')
swap('1. Select the **overdue** chip in the top bar.', '1. Select **Overdue** at the top of Home.')
swap('- Everything works with touch and with a keyboard.', '- Everything works with touch, and with a screen reader or keyboard if you use one.')
swap('- Every control can be reached and used with the keyboard. Dialogs trap focus and return it when closed.', '- Every control has a label for screen readers, and closing a sheet returns you to where you were.')
swap('controls are at least 24 pixels square', 'controls are at least 48 pixels square')
swap('Reloading the page removes them. Use **Reset sample data** in the developer bar to clear them on purpose.', 'Closing and reopening the app removes them. Use **Reset session data** in Account (under Developer) to clear them on purpose.')

writeFileSync(file, s)
console.log(missed.length ? `Not matched:\n- ${missed.join('\n- ')}` : 'all edits applied')
