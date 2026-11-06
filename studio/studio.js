const $ = id => document.getElementById(id);
const format = value => Number.isFinite(value) ? new Intl.NumberFormat('zh-CN', {maximumFractionDigits: 3}).format(Math.abs(value) < 1e-9 ? 0 : value) : '—';
const methods = {
  ols: '每个节点等权。用最小二乘找到满足加总关系的预测。',
  wls: '使用独立历史残差或显式方差。误差较大的节点通常调整更多。',
  bottom_up: '保留叶节点预测，再逐层加总。不使用上层原始预测。',
};
let result = null;
let worker = null;
let generation = 0;
let busy = false;
let loadGeneration = 0;
let savedWeights = null;

function message(text = '', error = false) {
  $('message').textContent = text;
  $('message').classList.toggle('error', error);
}

function invalidate() {
  generation++;
  if (worker) worker.terminate();
  worker = null;
  busy = false;
  result = null;
  $('export-report').disabled = true;
  $('period-select').disabled = true;
  $('run').disabled = false;
  $('run').textContent = '协调这组预测 ↗';
  $('engine-status').textContent = '输入已修改 · 等待重新计算';
  $('study-title').textContent = '等待重新计算';
  for (const id of ['before', 'after', 'observed']) $(id).textContent = '—';
  for (const id of ['chart', 'rows', 'score-table']) $(id).replaceChildren();
  $('evaluation-note').textContent = '计算后，单独比较一致性与误差。';
  message();
}

function download(name, content, type = 'application/json') {
  const url = URL.createObjectURL(new Blob([content], {type}));
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = name;
  anchor.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function request() {
  const source = $('source').value;
  if (source.length > 524288) throw new Error('输入过大：最多支持 524288 个字符单元。');
  // Pass the original JSON to MoonBit so duplicate keys are never discarded here.
  // The chosen method is supplied separately only when changing an existing study.
  return source;
}

function run() {
  if (busy) {
    invalidate();
    message('计算已取消。');
    return;
  }
  let source;
  try { source = request(); } catch (error) { return message(error.message, true); }
  message();
  result = null;
  $('export-report').disabled = true;
  $('period-select').disabled = true;
  busy = true;
  const id = ++generation;
  $('run').textContent = '取消计算 ×';
  $('engine-status').textContent = '正在协调预测…';
  worker = new Worker('/calculator.worker.js', {type: 'module'});
  const timeout = setTimeout(() => {
    if (id !== generation || !busy) return;
    invalidate();
    message('计算已超过 15 秒，已取消。请减少节点或周期后重试。', true);
  }, 15000);
  const fail = () => {
    clearTimeout(timeout);
    if (id !== generation) return;
    invalidate();
    message('计算引擎暂不可用，请确认已完成构建后重试。', true);
  };
  worker.onerror = fail;
  worker.onmessage = event => {
    clearTimeout(timeout);
    if (id !== generation) return;
    if (event.data.failure) return fail();
    worker.terminate(); worker = null; busy = false;
    $('run').textContent = '协调这组预测 ↗';
    let output;
    try { output = JSON.parse(event.data.output); } catch { return fail(); }
    if (output.status !== 'ok') {
      invalidate();
      return message(`输入未通过校验：${output.message}`, true);
    }
    result = output;
    $('engine-status').textContent = '计算完成 · MoonBit';
    $('study-title').textContent = result.title;
    $('export-report').disabled = false;
    const periods = $('period-select');
    periods.replaceChildren(...result.periods.map((row, index) => new Option(`周期 ${row.period}`, String(index))));
    periods.disabled = false;
    $('observed').textContent = result.evaluation?.horizons ?? 0;
    if (result.periods.some(row => row.coherent.some(x => x < 0))) message('结果中有负预测值。当前方法不施加非负约束，请结合业务场景复核。');
    drawPeriod(); drawScores();
  };
  worker.postMessage({id, source});
}

function element(tag, text, className) {
  const node = document.createElement(tag);
  if (text !== undefined) node.textContent = text;
  if (className) node.className = className;
  return node;
}

function svgNode(tag, attributes = {}, text) {
  const node = document.createElementNS('http://www.w3.org/2000/svg', tag);
  for (const [key, value] of Object.entries(attributes)) node.setAttribute(key, String(value));
  if (text !== undefined) node.textContent = text;
  return node;
}

function drawPeriod() {
  if (!result) return;
  const row = result.periods[Number($('period-select').value)];
  $('before').textContent = format(row.coherence_before);
  $('after').textContent = format(row.coherence_after);
  $('unit-before').textContent = result.unit;
  $('unit-after').textContent = result.unit;
  $('table-caption').textContent = `周期 ${row.period} · ${result.unit} · 显示值最多保留三位小数`;
  $('rows').replaceChildren(...result.node_ids.map((name, i) => {
    const tr = element('tr');
    const delta = row.adjustments[i];
    tr.append(element('td', name), element('td', format(row.base[i])), element('td', format(row.coherent[i])), element('td', `${delta > 1e-9 ? '+' : ''}${format(delta)}`, delta > 1e-9 ? 'delta-positive' : delta < -1e-9 ? 'delta-negative' : ''), element('td', row.actual ? format(row.actual[i]) : '—'));
    return tr;
  }));
  const ids = result.node_ids;
  const all = [...row.base, ...row.coherent, ...(row.actual ?? [])];
  let lo = Math.min(0, ...all), hi = Math.max(0, ...all);
  if (lo === hi) hi = lo + 1;
  const span = hi - lo;
  hi += span * .05;
  if (lo < 0) lo -= span * .05;
  const width = 700, left = 115, right = 20, height = ids.length * 42 + 38;
  const x = value => left + (value - lo) / (hi - lo) * (width - left - right);
  const svg = svgNode('svg', {viewBox: `0 0 ${width} ${height}`, role: 'img', 'aria-label': '各节点预测值。完整数字见下方明细表。'});
  svg.append(svgNode('line', {x1:x(0), x2:x(0), y1:0, y2:height - 24, stroke:'#ccd6cb'}));
  ids.forEach((name, i) => {
    const y = i * 42 + 14;
    const label = name.length > 10 ? name.slice(0, 9) + '…' : name;
    svg.append(svgNode('text', {x:0, y:y + 7}, label));
    svg.append(svgNode('line', {x1:left, x2:width - right, y1:y + 19, y2:y + 19, stroke:'#e9ece4'}));
    for (const [value, dy, fill] of [[row.base[i], 0, '#b8c8bc'], [row.coherent[i], 10, '#286153']]) {
      const bar = svgNode('rect', {x:Math.min(x(0),x(value)), y:y + dy, width:Math.max(.8,Math.abs(x(value)-x(0))), height:7, rx:2, fill});
      bar.append(svgNode('title', {}, `${name}: ${format(value)} ${result.unit}`));
      svg.append(bar);
    }
    if (row.actual) svg.append(svgNode('circle', {cx:x(row.actual[i]), cy:y + 8, r:3.5, fill:'#fcfbf7', stroke:'#bd8058', 'stroke-width':1.5}));
  });
  for (let i=0;i<=4;i++) {
    const value = lo + (hi-lo)*i/4;
    svg.append(svgNode('text', {x:x(value), y:height - 4, 'text-anchor':i===0?'start':i===4?'end':'middle', class:'axis-label'}, format(value)));
  }
  $('chart').replaceChildren(svg);
}

function drawScores() {
  const evaluation = result.evaluation;
  if (!evaluation) {
    $('evaluation-note').textContent = '这份输入没有实际值，只能检查加总一致性。补充独立留出实际值后，才能比较误差。';
    $('score-table').replaceChildren();
    return;
  }
  const worse = evaluation.nodes.filter(row => row.reconciled_mae > row.base_mae + 1e-9).length;
  $('evaluation-note').textContent = `使用 ${evaluation.horizons} 个独立留出周期。${worse} 个节点的 MAE 变大；结果完整保留，不能仅凭一致性判断方法好坏。`;
  const table = element('table');
  const caption = element('caption', `各节点平均绝对误差 MAE · ${result.unit}`);
  const head = element('tr');
  for (const label of ['节点','原始 MAE','协调 MAE','变化']) { const th=element('th',label);th.scope='col';head.append(th); }
  const thead = element('thead'); thead.append(head);
  const tbody = element('tbody');
  for (const row of evaluation.nodes) {
    const delta = row.reconciled_mae - row.base_mae;
    const tr = element('tr');
    tr.append(element('td',row.id),element('td',format(row.base_mae)),element('td',format(row.reconciled_mae)),element('td',delta>1e-9?`增加 ${format(delta)}`:delta < -1e-9?`减少 ${format(-delta)}`:'持平',delta>1e-9?'worse':''));
    tbody.append(tr);
  }
  table.append(caption,thead,tbody); $('score-table').replaceChildren(table);
}

async function loadCase() {
  const id = ++loadGeneration;
  savedWeights = null;
  invalidate();
  $('run').disabled = true;
  try {
    const response = await fetch(`/cases/${$('case-select').value}.json`);
    if (!response.ok) throw new Error();
    const source = await response.text();
    if (id !== loadGeneration) return;
    $('source').value = source;
    $('method-select').value = JSON.parse(source).method;
    $('method-note').textContent = methods[$('method-select').value];
    $('run').disabled = false;
    run();
  } catch { if (id === loadGeneration) { $('run').disabled = false; message('样例暂不可用，请导入自己的 JSON 文件。',true); } }
}

$('case-select').addEventListener('change', loadCase);
$('method-select').addEventListener('change', () => {
  // An explicit method change rewrites input; direct runs preserve the original text.
  const selected = $('method-select').value;
  try {
    const input = JSON.parse($('source').value);
    // Rewriting is explicit when the user changes the selected calculation method.
    input.method = selected;
    if (selected !== 'wls') {
      if (input.calibration || input.variances) {
        savedWeights = {};
        for (const key of ['calibration', 'variances', 'floor_ratio']) if (key in input) savedWeights[key] = input[key];
      }
      delete input.calibration; delete input.variances; delete input.floor_ratio;
    } else if (!input.calibration && !input.variances && savedWeights) {
      Object.assign(input, structuredClone(savedWeights));
    }
    $('source').value = JSON.stringify(input,null,2);
    invalidate();
    $('method-note').textContent = methods[selected];
    if (selected === 'wls' && !input.calibration && !input.variances) return message('WLS 需要历史残差或显式方差。请在输入中补充，或重新载入含校准数据的门店样例。');
    run();
  } catch { message('请先修正 JSON 格式，再切换协调方式。',true); }
});
$('period-select').addEventListener('change',drawPeriod);
$('run').addEventListener('click',run);
$('source').addEventListener('input', () => {
  savedWeights = null;
  loadGeneration++; invalidate();
  try {
    const mode = JSON.parse($('source').value).method;
    if (methods[mode]) { $('method-select').value=mode; $('method-note').textContent=methods[mode]; }
  } catch { /* The calculation boundary reports malformed input on request. */ }
});
$('import').addEventListener('change',async event => {
  const file = event.target.files[0];
  event.target.value='';
  if (!file) return;
  const id=++loadGeneration;
  savedWeights=null;
  invalidate();
  if (file.size>1048576) return message('文件超过 1 MiB，请缩小输入。',true);
  try {
    const source=new TextDecoder('utf-8',{fatal:true}).decode(await file.arrayBuffer());
    if (id!==loadGeneration) return;
    $('source').value=source;
    try {
      const mode = JSON.parse(source).method;
      if (methods[mode]) { $('method-select').value=mode; $('method-note').textContent=methods[mode]; }
    } catch { /* Keep the original text for the strict MoonBit decoder. */ }
    // Do not normalize imported input: the engine must see duplicate keys verbatim.
    $('study-title').textContent='导入的数据 · 等待计算';
    message('文件已载入，请点击“协调这组预测”。');
  } catch { message('文件不是有效 UTF-8 文本。',true); }
});
$('export-input').addEventListener('click',()=>download('tingchao-input.json',$('source').value));
$('export-report').addEventListener('click',()=>{if(result)download('tingchao-report.json',JSON.stringify(result,null,2));});
loadCase();
