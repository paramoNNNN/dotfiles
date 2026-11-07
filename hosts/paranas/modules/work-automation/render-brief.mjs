// Preserve the original daily briefing layout and Plane cycle membership rules.
export function renderBrief(gitlab, calendar, rows, privateConfig) {
  const meetings = Array.isArray(calendar.meetings) ? calendar.meetings : [];
  const asArray = value => Array.isArray(value) ? value : (value?.results || []);
  const now = new Date(gitlab.until);
  const windowStart = new Date(gitlab.since);
  const inWindow = value => value && new Date(value) >= windowStart && new Date(value) < now;
  const esc = value => String(value ?? '').replace(/\|/g, '\\|').replace(/\r?\n/g, ' ');
  const link = (label, url) => url ? `[${esc(label)}](${url})` : esc(label);
  const jalaliDate = value => {
    const parts = new Intl.DateTimeFormat('en-US-u-ca-persian', { timeZone: 'Asia/Tehran', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date(value));
    const get = type => parts.find(part => part.type === type)?.value || '';
    return `${get('year')}/${get('month')}/${get('day')}`;
  };
  const tehranDayNumber = value => {
    const parts = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Tehran', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date(value));
    const get = type => Number(parts.find(part => part.type === type)?.value);
    return Math.floor(Date.UTC(get('year'), get('month') - 1, get('day')) / 86400000);
  };
  const relativeDue = targetDate => {
    const delta = tehranDayNumber(`${targetDate}T12:00:00Z`) - tehranDayNumber(gitlab.generatedAt);
    if (delta === 0) return 'due today';
    return delta > 0 ? `${delta} day${delta === 1 ? '' : 's'} remaining` : `${-delta} day${delta === -1 ? '' : 's'} overdue`;
  };
  const itemLine = item => `  - ${link(item.name, item.url)} — **${esc(item.state)}**${item.owner ? ` — ${esc(item.owner)}` : ''}${item.targetDate ? ` — due ${jalaliDate(item.targetDate)} (${relativeDue(item.targetDate)})` : ''}`;
  const cycleWorkItemId = relation => {
    const related = relation?.issue?.id ?? relation?.issue_id ?? relation?.issue ?? relation?.work_item?.id ?? relation?.work_item_id ?? relation?.work_item;
    if (related !== undefined && related !== null && typeof related !== 'object') return String(related);
    // Some Plane releases return expanded work items directly instead of a
    // cycle-to-item relation. Only then is the row's own id the work-item id.
    if (relation?.id && (relation.name || relation.sequence_id)) return String(relation.id);
    return null;
  };
  const projects = rows.map(row => {
    const states = asArray(row.statesResponse);
    const stateMap = new Map(states.map(state => [String(state.id), state]));
    const cycleRows = asArray(row.cycleItemsResponse);
    const currentCycleItemIds = new Set(cycleRows.map(cycleWorkItemId).filter(Boolean));
    return { ...row.project, activeCycle: row.activeCycle || null, cycleRowCount: cycleRows.length, currentCycleItemIds, stateMap, workItems: asArray(row.workItemsResponse), pages: asArray(row.pagesResponse), pagesError: row.pagesResponse?.error || row.pagesResponse?.message || null };
  });
  const workItems = projects.flatMap(project => project.workItems.map(item => {
    const stateId = String(item.state?.id || item.state || '');
    const state = item.state_detail || (typeof item.state === 'object' ? item.state : null) || project.stateMap.get(stateId) || {};
    const group = String(state.group || state.state_group || '').toLowerCase();
    return {
      id: String(item.id),
      project: project.projectName || project.projectIdentifier,
      name: item.name || 'Untitled',
      state: state.name || stateId || 'Unknown',
      group,
      priority: String(item.priority || 'none').toLowerCase(),
      owner: asArray(item.assignees).map(person => person.display_name || person.name || person.email || person).join(', '),
      targetDate: item.target_date || null,
      updatedAt: item.updated_at || null,
      completedAt: item.completed_at || null,
      cancelledAt: item.cancelled_at || null,
      inCurrentCycle: Boolean(project.activeCycle && project.currentCycleItemIds.has(String(item.id))),
      url: `${privateConfig.planeBaseUrl}/${privateConfig.planeWorkspaceSlug}/projects/${project.projectId}/issues/${item.id}`
    };
  }));
  const open = workItems.filter(item => !item.completedAt && !item.cancelledAt && !['completed', 'cancelled', 'canceled'].includes(item.group));
  const current = open.filter(item => item.inCurrentCycle);
  const cycleRowsFound = projects.reduce((total, project) => total + project.cycleRowCount, 0);
  const cycleIdsResolved = projects.reduce((total, project) => total + project.currentCycleItemIds.size, 0);
  const currentInProgress = current.filter(item => item.group === 'started');
  const currentTodo = current.filter(item => item.group !== 'started');
  const overdue = open.filter(item => item.targetDate && new Date(`${item.targetDate}T23:59:59Z`) < now);
  const upcoming = open.filter(item => item.targetDate && new Date(`${item.targetDate}T23:59:59Z`) >= now && new Date(`${item.targetDate}T23:59:59Z`) <= new Date(now.getTime() + 7 * 86400000));
  const recentlyChanged = workItems.filter(item => inWindow(item.updatedAt) || inWindow(item.completedAt));
  const failedPipelines = gitlab.pipelines.filter(pipeline => ['failed', 'canceled'].includes(pipeline.status));
  const openMrs = gitlab.mergeRequests.filter(mr => mr.state === 'opened');
  const recentPages = projects.flatMap(project => project.pages.map(page => ({ project: project.projectName || project.projectIdentifier, name: page.name || 'Untitled', updatedAt: page.updated_at, url: `${privateConfig.planeBaseUrl}/${privateConfig.planeWorkspaceSlug}/projects/${project.projectId}/pages/${page.id}` }))).filter(page => page.updatedAt).sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt))).slice(0, 10);
  const pagesUnavailable = projects.some(project => project.pagesError);
  const section = (title, values, render, empty = '- Nothing found.') => [`## ${title}`, '', ...(values.length ? values.map(render) : [empty]), ''];
  const projectSection = (title, values, empty = '- Nothing found.') => {
    const grouped = new Map();
    for (const item of values) {
      const project = item.project || 'Unknown project';
      if (!grouped.has(project)) grouped.set(project, []);
      grouped.get(project).push(item);
    }
    const body = [...grouped].flatMap(([project, items]) => [`- **${esc(project)}**`, ...items.map(itemLine)]);
    return [`## ${title}`, '', ...(body.length ? body : [empty]), ''];
  };
  const userSection = (title, values, userFor, render, empty = '- Nothing found.') => {
    const grouped = new Map();
    for (const value of values) {
      const user = userFor(value) || 'Unknown user';
      if (!grouped.has(user)) grouped.set(user, []);
      grouped.get(user).push(value);
    }
    const body = [...grouped].flatMap(([user, groupedValues]) => [`- **${esc(user)}**`, ...groupedValues.map(render)]);
    return [`## ${title}`, '', ...(body.length ? body : [empty]), ''];
  };
  const lines = [
    '---',
    'type: briefing',
    `date: ${gitlab.reportDate}`,
    `jalali_date: ${jalaliDate(gitlab.reportDate)}`,
    `generated_at: ${gitlab.generatedAt}`,
    'generated_by: work-automation',
    'sources:',
    '  - plane',
    '  - gitlab',
    '---',
    '',
    `# ${privateConfig.reportTitle} brief — ${jalaliDate(gitlab.reportDate)}`,
    '',
    '> [!info]',
    '> Generated deterministically from Plane and GitLab. Personal notes and meeting context remain elsewhere in this vault.',
    '',
    '## Remaining todos from daily notes',
    '',
    '```tasks',
    'not done',
    String.raw`path regex matches /^(Daily\/\d{4}-\d{2}-\d{2}|Archive\/\d{4}-\d{2}\/Daily\/\d{4}-\d{2}-\d{2})\.md$/`,
    'sort by filename',
    '```',
    '',
    '## Meetings requiring documentation — past 30 days',
    '',
    ...(meetings.length ? meetings.map(meeting => `- ${jalaliDate(meeting.start)} ${String(meeting.start).slice(11, 16)} — [[${String(meeting.path).replace(/\.md$/, '')}|${esc(meeting.title)}]] — missing: ${meeting.missingSections.map(esc).join(', ')}`) : [calendar.calendarAvailable === false ? '- Calendar feed unavailable; meeting audit could not be completed.' : calendar.calendarConfigured ? '- All non-routine meetings in the past 30 days are documented.' : '- Calendar feed is not configured.']),
    '',
    '## At a glance',
    '',
    `- ${gitlab.commits.length} GitLab commit(s)`,
    `- ${openMrs.length} open merge request(s) touched since yesterday`,
    `- ${failedPipelines.length} failed or canceled pipeline(s)`,
    `- ${recentlyChanged.length} Plane work item(s) changed`,
    `- ${current.length} open current-cycle item(s) across ${projects.filter(project => project.activeCycle).length} project(s)`,
    ...(cycleRowsFound > 0 && current.length === 0 ? [`- ⚠️ Plane returned ${cycleRowsFound} cycle membership row(s); ${cycleIdsResolved} item ID(s) were resolved but none matched an open project work item.`] : []),
    '',
    ...projectSection('Deadlines', [...overdue, ...upcoming], '- No overdue or next-seven-day deadlines found.'),
    ...projectSection('Current cycle — in progress', currentInProgress),
    ...projectSection('Current cycle — todo', currentTodo),
    ...projectSection('Plane changes yesterday', recentlyChanged),
    ...userSection('GitLab commits', gitlab.commits, commit => commit.author_name || commit.author_email, commit => `  - ${link(commit.title, commit.web_url)}${commit.short_id ? ` (\`${commit.short_id}\`)` : ''}`),
    ...userSection('Open merge requests touched yesterday', openMrs, mr => mr.author?.name || mr.author?.username, mr => `  - ${link(`!${mr.iid} ${mr.title}`, mr.web_url)}`),
    ...userSection('Pipelines needing attention', failedPipelines, pipeline => pipeline.user?.name || pipeline.user?.username, pipeline => `  - ${link(`#${pipeline.id} ${pipeline.ref || ''}`, pipeline.web_url)} — **${esc(pipeline.status)}**`),
    ...section('Recently updated Plane pages', recentPages, page => `- ${link(`${page.project}: ${page.name}`, page.url)} — ${jalaliDate(page.updatedAt)}`, pagesUnavailable ? '- Unavailable: this self-hosted Plane release does not expose Pages to API-key clients.' : '- No recently updated pages found.'),
    '## Source systems',
    '',
    `- [Plane](${privateConfig.planeBaseUrl}/)`,
    `- [GitLab](${privateConfig.gitlabProjectWebUrl})`,
    ''
  ];
  const markdown = lines.join('\n');
  const fileName = `${gitlab.reportDate}.md`;
  return { reportDate: gitlab.reportDate, fileName, markdown };
}
