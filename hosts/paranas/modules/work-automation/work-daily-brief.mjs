import { execFileSync } from 'node:child_process';
import { mkdir, open, rename, unlink } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { resolve, dirname } from 'node:path';
import { pathToFileURL } from 'node:url';
import { renderBrief } from './render-brief.mjs';

export function reportWindow(now = new Date()) {
  const localDate = value => {
    const parts = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'Asia/Tehran', year: 'numeric', month: '2-digit', day: '2-digit',
    }).formatToParts(value);
    const get = type => parts.find(part => part.type === type).value;
    return `${get('year')}-${get('month')}-${get('day')}`;
  };
  const offset = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Tehran', timeZoneName: 'longOffset',
  }).formatToParts(now).find(part => part.type === 'timeZoneName').value.replace('GMT', '');
  const until = new Date(`${localDate(now)}T00:00:00${offset}`);
  const since = new Date(until.getTime() - 86400000);
  return { reportDate: localDate(since), since: since.toISOString(), until: until.toISOString(), generatedAt: now.toISOString() };
}

export function selectCycle(cycles, reportDate) {
  cycles = cycles.filter(cycle => !cycle.deleted_at && !cycle.archived_at);
  const activeStatuses = new Set(['current', 'active', 'started', 'in-progress', 'in_progress']);
  return cycles.find(cycle => cycle.is_current === true || activeStatuses.has(String(cycle.status || cycle.cycle_view || cycle.state || '').toLowerCase()))
    || cycles.find(cycle => {
      const start = String(cycle.start_date || '').slice(0, 10);
      const end = String(cycle.end_date || '').slice(0, 10);
      return start && end && start <= reportDate && reportDate <= end;
    }) || (cycles.length === 1 ? cycles[0] : null);
}

export function makeClient(base, headers, kind, fetcher = fetch) {
  return async function list(path, query = {}) {
    const url = new URL(`${base.replace(/\/$/, '')}/${path}`);
    for (const [key, value] of Object.entries({ per_page: 100, ...query })) url.searchParams.set(key, value);
    if (kind === 'gitlab') url.searchParams.set('page', '1');
    const rows = [];
    const seen = new Set();
    for (let page = 0; page < 1000; page++) {
      if (seen.has(url.href)) throw new Error(`${kind}: repeated pagination cursor`);
      seen.add(url.href);
      let response;
      try {
        response = await fetcher(url, { headers, signal: AbortSignal.timeout(30000), redirect: 'error' });
      } catch {
        throw new Error(`${kind}: request failed or timed out`);
      }
      if (!response.ok) throw new Error(`${kind}: HTTP ${response.status}`);
      let body;
      try { body = await response.json(); } catch { throw new Error(`${kind}: invalid JSON response`); }
      const values = Array.isArray(body) ? body : body.results;
      if (!Array.isArray(values)) throw new Error(`${kind}: expected an array of results`);
      rows.push(...values);
      const next = kind === 'gitlab' ? response.headers.get('x-next-page')
        : body.next_page_results !== false && body.next_cursor;
      if (!next) return rows;
      url.searchParams.set(kind === 'gitlab' ? 'page' : 'cursor', String(next));
    }
    throw new Error(`${kind}: pagination limit exceeded`);
  };
}

export async function collectSources(config, window, fetcher = fetch) {
  const gitlab = makeClient(`${config.GITLAB_BASE_URL}/api/v4`, { 'PRIVATE-TOKEN': config.GITLAB_API_TOKEN }, 'gitlab', fetcher);
  const plane = makeClient(`${config.PLANE_BASE_URL}/api/v1`, { 'X-API-Key': config.PLANE_API_KEY }, 'plane', fetcher);
  // The former n8n workflow inserted this value directly into the URL, so
  // existing configurations may already encode namespace separators as %2F.
  let projectId = config.GITLAB_PROJECT_ID;
  try { projectId = decodeURIComponent(projectId); }
  catch (error) { if (!(error instanceof URIError)) throw error; }
  const gitlabProject = `projects/${encodeURIComponent(projectId)}`;
  // Fetch sequentially to keep peak memory and upstream load modest.
  const commits = await gitlab(`${gitlabProject}/repository/commits`, { since: window.since, until: window.until });
  const mergeRequests = await gitlab(`${gitlabProject}/merge_requests`, { scope: 'all', updated_after: window.since, order_by: 'updated_at', sort: 'desc' });
  const pipelines = await gitlab(`${gitlabProject}/pipelines`, { updated_after: window.since, order_by: 'updated_at', sort: 'desc' });
  const workspace = `workspaces/${encodeURIComponent(config.PLANE_WORKSPACE_SLUG)}/projects/`;
  const projects = await plane(workspace);
  const rows = [];
  for (const project of projects) {
    const path = `${workspace}${encodeURIComponent(project.id)}/`;
    const workItemsResponse = await plane(`${path}work-items/`, { expand: 'state,assignees' });
    const cyclesResponse = await plane(`${path}cycles/`);
    const activeCycle = selectCycle(cyclesResponse, window.reportDate);
    // No cycle means no membership query, rather than a deliberate invalid URL.
    const cycleItemsResponse = activeCycle ? await plane(`${path}cycles/${encodeURIComponent(activeCycle.id)}/cycle-issues/`) : [];
    const statesResponse = await plane(`${path}states/`);
    let pagesResponse;
    try { pagesResponse = await plane(`${path}pages/`); }
    catch (error) {
      // Self-hosted Plane versions may not expose Pages to API keys.
      if (!/HTTP (403|404)$/.test(error.message)) throw error;
      pagesResponse = { error: 'Pages unavailable to this API client' };
    }
    rows.push({ project: { projectId: project.id, projectName: project.name, projectIdentifier: project.identifier }, activeCycle, workItemsResponse, cyclesResponse, cycleItemsResponse, statesResponse, pagesResponse });
  }
  return { gitlab: { ...window, commits, mergeRequests, pipelines }, rows };
}

export async function writeBrief(vault, fileName, markdown) {
  const target = resolve(vault, 'Briefings', fileName);
  await mkdir(dirname(target), { recursive: true, mode: 0o2770 });
  const temporary = `${target}.${randomUUID()}.tmp`;
  try {
    const file = await open(temporary, 'wx', 0o660);
    try { await file.writeFile(markdown, 'utf8'); await file.sync(); }
    finally { await file.close(); }
    await rename(temporary, target);
  } finally { await unlink(temporary).catch(error => { if (error.code !== 'ENOENT') throw error; }); }
  return target;
}

export async function main(env = process.env) {
  for (const key of ['GITLAB_BASE_URL', 'GITLAB_PROJECT_ID', 'GITLAB_API_TOKEN', 'PLANE_BASE_URL', 'PLANE_WORKSPACE_SLUG', 'PLANE_API_KEY']) {
    if (!env[key]) throw new Error(`Missing required environment variable: ${key}`);
  }
  const config = { ...env, GITLAB_BASE_URL: env.GITLAB_BASE_URL.replace(/\/$/, ''), PLANE_BASE_URL: env.PLANE_BASE_URL.replace(/\/$/, '') };
  const window = reportWindow();
  const calendar = JSON.parse(execFileSync('prepare-calendar-meetings', { encoding: 'utf8', env }));
  const { gitlab, rows } = await collectSources(config, window);
  const brief = renderBrief(gitlab, calendar, rows, {
    reportTitle: env.WORK_REPORT_TITLE || 'Work', planeBaseUrl: config.PLANE_BASE_URL,
    planeWorkspaceSlug: env.PLANE_WORKSPACE_SLUG, gitlabProjectWebUrl: env.GITLAB_PROJECT_WEB_URL || '',
  });
  const target = await writeBrief(env.OBSIDIAN_VAULT_ROOT || '/var/lib/obsidian-vault', brief.fileName, brief.markdown);
  console.log(`Wrote briefing for ${brief.reportDate} to ${target}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  main().catch(error => {
    // Never dump HTTP bodies, request headers, environment values, or private URLs.
    console.error(`Daily brief failed: ${error.message.startsWith('Missing required') || /^(gitlab|plane):/.test(error.message) ? error.message : 'helper or file operation failed'}`);
    process.exitCode = 1;
  });
}
