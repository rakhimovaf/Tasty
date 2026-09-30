import http from "node:http";

const port = Number(process.env.PORT || 8787);
const apiKey = process.env.OPENAI_API_KEY;
const model = process.env.OPENAI_MODEL || "gpt-5-mini";
const requestLog = new Map();
if (!apiKey) { console.error("OPENAI_API_KEY is required."); process.exit(1); }

function sendJSON(response, status, body) {
  response.writeHead(status, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
  response.end(JSON.stringify(body));
}
function readJSON(request) {
  return new Promise((resolve, reject) => {
    let total = 0; const chunks = [];
    request.on("data", chunk => { total += chunk.length; if (total > 80_000) { reject(new Error("Request is too large.")); request.destroy(); } else chunks.push(chunk); });
    request.on("end", () => { try { resolve(JSON.parse(Buffer.concat(chunks).toString("utf8"))); } catch { reject(new Error("Request must contain valid JSON.")); } });
    request.on("error", reject);
  });
}
function isRateLimited(request) {
  const ip = request.socket.remoteAddress || "unknown";
  const cutoff = Date.now() - 60_000;
  const recent = (requestLog.get(ip) || []).filter(time => time > cutoff);
  recent.push(Date.now()); requestLog.set(ip, recent);
  return recent.length > 30;
}
function input(body) {
  const messages = Array.isArray(body.messages) ? body.messages.slice(-12) : [];
  const valid = messages.length > 0 && messages.every(message => message && ["user", "assistant"].includes(message.role) && typeof message.content === "string" && message.content.length <= 4_000);
  if (!valid) throw new Error("Messages are missing or invalid.");
  return [{ role: "developer", content: "You are Tasty's helpful cooking assistant. Reply in the user's language (Uzbek when appropriate). Give practical, concise cooking guidance for recipes, ingredient substitutions, and cooking techniques. Mention food safety when relevant. Do not diagnose medical conditions or give medical nutrition advice." }, ...messages];
}
async function askOpenAI(messages) {
  const response = await fetch("https://api.openai.com/v1/responses", { method: "POST", headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" }, body: JSON.stringify({ model, input: messages, max_output_tokens: 700 }) });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) { console.error("OpenAI request failed:", response.status, body.error?.message); throw new Error("The AI provider is temporarily unavailable."); }
  const reply = body.output?.flatMap(item => item.content || []).filter(item => item.type === "output_text").map(item => item.text).join("\n").trim();
  if (!reply) throw new Error("The AI provider returned no text.");
  return reply;
}
http.createServer(async (request, response) => {
  if (request.method === "GET" && request.url === "/health") return sendJSON(response, 200, { ok: true });
  if (request.method !== "POST" || request.url !== "/chat") return sendJSON(response, 404, { error: "Not found." });
  if (isRateLimited(request)) return sendJSON(response, 429, { error: "Too many requests. Please try again shortly." });
  try { sendJSON(response, 200, { reply: await askOpenAI(input(await readJSON(request))) }); }
  catch (error) { sendJSON(response, 400, { error: error instanceof Error ? error.message : "Unable to process request." }); }
}).listen(port, () => console.log(`Tasty AI service listening on port ${port}`));
