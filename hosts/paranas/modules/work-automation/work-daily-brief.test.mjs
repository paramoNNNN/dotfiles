import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { collectSources, makeClient, reportWindow, selectCycle, writeBrief } from './work-daily-brief.mjs';
import { renderBrief } from './render-brief.mjs';

const window = reportWindow(new Date('2026-10-15T03:15:00Z'));
const config = {
  GITLAB_BASE_URL: 'https://gitlab.test', GITLAB_PROJECT_ID: 'group/project', GITLAB_API_TOKEN: 'gitlab-secret',
  PLANE_BASE_URL: 'https://plane.test', PLANE_WORKSPACE_SLUG: 'work', PLANE_API_KEY: 'plane-secret',
};
const privateConfig = { reportTitle: 'Work', planeBaseUrl: config.PLANE_BASE_URL, planeWorkspaceSlug: 'work', gitlabProjectWebUrl: 'https://gitlab.test/project' };
const reply = (body, status = 200, headers = {}) => new Response(JSON.stringify(body), { status, headers });

test('report dates follow Tehran midnight, including year rollover', () => {
  assert.equal(window.reportDate, '2026-10-14');
  assert.equal(window.since, '2026-10-13T20:30:00.000Z');
  assert.equal(window.until, '2026-10-14T20:30:00.000Z');
  assert.equal(reportWindow(new Date('2027-01-01T03:15:00Z')).reportDate, '2026-12-31');
});

test('GitLab and Plane pagination retain every page and reject looping cursors', async () => {
  const gitlab = makeClient('https://gitlab.test', {}, 'gitlab', async url =>
    url.searchParams.get('page') === '1' ? reply([{ id: 1 }], 200, { 'x-next-page': '2' }) : reply([{ id: 2 }]));
  assert.deepEqual(await gitlab('items'), [{ id: 1 }, { id: 2 }]);
  const plane = makeClient('https://plane.test', {}, 'plane', async url =>
    !url.searchParams.has('cursor') ? reply({ results: [{ id: 1 }], next_cursor: 'next', next_page_results: true }) : reply({ results: [{ id: 2 }], next_page_results: false }));
  assert.deepEqual(await plane('items'), [{ id: 1 }, { id: 2 }]);
  const loop = makeClient('https://plane.test', {}, 'plane', async () => reply({ results: [], next_cursor: 'same', next_page_results: true }));
  await assert.rejects(loop('items'), /repeated pagination cursor/);
});

test('GitLab project URLs accept numeric, raw, and n8n-encoded project IDs', async () => {
  for (const [projectId, expected] of [
    ['42', '42'],
    ['group/project', 'group%2Fproject'],
    ['group%2Fproject', 'group%2Fproject'],
    ['group%2Fsubgroup%2Fproject', 'group%2Fsubgroup%2Fproject'],
  ]) {
    const paths = [];
    await collectSources({ ...config, GITLAB_PROJECT_ID: projectId }, window, async url => {
      if (url.host === 'gitlab.test') paths.push(url.pathname);
      return reply([]);
    });
    assert.deepEqual(paths, [
      `/api/v4/projects/${expected}/repository/commits`,
      `/api/v4/projects/${expected}/merge_requests`,
      `/api/v4/projects/${expected}/pipelines`,
    ]);
  }
});

test('empty projects still produce a daily brief; upstream failure cannot replace it', async () => {
  const vault = await mkdtemp(join(tmpdir(), 'work-brief-'));
  try {
    const { gitlab, rows } = await collectSources(config, window, async () => reply([]));
    const brief = renderBrief(gitlab, { meetings: [], calendarConfigured: false }, rows, privateConfig);
    assert.match(brief.markdown, /0 GitLab commit/);
    assert.match(brief.markdown, /Calendar feed is not configured/);
    const target = await writeBrief(vault, brief.fileName, brief.markdown);
    await assert.rejects(collectSources(config, window, async () => reply({}, 503)), /gitlab: HTTP 503/);
    assert.equal(await readFile(target, 'utf8'), brief.markdown);
    await writeBrief(vault, brief.fileName, 'replacement\n');
    assert.equal(await readFile(target, 'utf8'), 'replacement\n');
  } finally { await rm(vault, { recursive: true, force: true }); }
});

test('cycle membership, expanded states, calendar outages, and Markdown escapes survive migration', async () => {
  const fetcher = async (url, options) => {
    assert.equal(options.redirect, 'error');
    if (url.host === 'gitlab.test') {
      assert.equal(options.headers['PRIVATE-TOKEN'], 'gitlab-secret');
      assert.match(url.pathname, /group%2Fproject/);
      return reply(url.pathname.endsWith('/commits') ? [{ id: 'commit', title: 'Fix | thing\nnow', short_id: 'abc123', author_name: 'Alice' }] : []);
    }
    assert.equal(options.headers['X-API-Key'], 'plane-secret');
    if (url.pathname.endsWith('/projects/')) return reply({ results: [{ id: 'p1', name: 'Project' }] });
    if (url.pathname.endsWith('/work-items/')) return reply({ results: [{ id: 'task', name: 'Current task', state: 's1' }, { id: 'other', name: 'Other task', state: 's1' }] });
    if (url.pathname.endsWith('/cycles/')) return reply([{ id: 'cycle', name: 'Active', is_current: true }]);
    if (url.pathname.endsWith('/cycle-issues/')) return reply([{ id: 'relation', issue: { id: 'task' } }]);
    if (url.pathname.endsWith('/states/')) return reply([{ id: 's1', name: 'Doing', group: 'started' }]);
    if (url.pathname.endsWith('/pages/')) return reply({}, 403);
    throw new Error('Unexpected endpoint');
  };
  const { gitlab, rows } = await collectSources(config, window, fetcher);
  const brief = renderBrief(gitlab, { meetings: [], calendarAvailable: false, calendarConfigured: false }, rows, privateConfig);
  assert.match(brief.markdown, /1 open current-cycle item/);
  assert.match(brief.markdown, /Current task.*Doing/);
  assert.doesNotMatch(brief.markdown, /Other task/);
  assert.match(brief.markdown, /Fix \\\| thing now.*`abc123`/);
  assert.match(brief.markdown, /Calendar feed unavailable/);
  assert.match(brief.markdown, /Unavailable: this self-hosted Plane/);
  assert.match(brief.markdown, /path regex matches.*\\d\{4\}/);
  assert.ok(brief.markdown.startsWith('---\ntype: briefing\n'));
  assert.equal(selectCycle([{ id: 'archived', is_current: true, archived_at: 'date' }], window.reportDate), null);
});

test('an actual Plane failure is not silently described as an empty cycle or unavailable Pages', async () => {
  const fetcher = async url => {
    if (url.host === 'gitlab.test') return reply([]);
    if (url.pathname.endsWith('/projects/')) return reply([{ id: 'p1' }]);
    if (url.pathname.endsWith('/cycles/')) return reply([{ id: 'c1', is_current: true }]);
    if (url.pathname.endsWith('/cycle-issues/')) return reply({}, 500);
    return reply([]);
  };
  await assert.rejects(collectSources(config, window, fetcher), /plane: HTTP 500/);
});
