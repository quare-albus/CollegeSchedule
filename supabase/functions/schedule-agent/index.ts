import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
const MODEL = "google/gemini-2.5-flash";
const CONTEXT = {
  academic_program: "III MBBS Part-II",
  academic_term: "VII Term",
  batch: "J3 Batch",
  period_start: "2026-09-07",
  period_end: "2027-01-24",
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const schema = {
  type: "object",
  properties: {
    classes: {
      type: "array",
      items: {
        type: "object",
        properties: {
          class_date: { type: ["string", "null"] },
          day: { type: ["string", "null"] },
          start_time: { type: ["string", "null"] },
          end_time: { type: ["string", "null"] },
          session_type: { type: ["string", "null"] },
          subject: { type: ["string", "null"] },
          topic: { type: ["string", "null"] },
          faculty: { type: ["string", "null"] },
          venue: { type: ["string", "null"] },
          batch: { type: ["string", "null"] },
          raw_text: { type: ["string", "null"] },
          confidence: { type: ["number", "null"] },
        },
        required: [
          "class_date", "day", "start_time", "end_time", "session_type",
          "subject", "topic", "faculty", "venue", "batch", "raw_text", "confidence",
        ],
        additionalProperties: false,
      },
    },
  },
  required: ["classes"],
  additionalProperties: false,
};

function response(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function dataUrl(mime: string, base64: string) {
  return `data:${mime};base64,${base64}`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return response({ error: "POST required" }, 405);

  const apiKey = Deno.env.get("OPENROUTER_API_KEY");
  if (!apiKey) return response({ error: "OPENROUTER_API_KEY is not configured" }, 500);

  try {
    const body = await req.json();
    if (!Array.isArray(body?.files) || body.files.length === 0) {
      return response({ error: "files array is required" }, 400);
    }
    if (body.files.length > 10) return response({ error: "Maximum 10 files per request" }, 413);

    const content: any[] = [{
      type: "text",
      text: `You are the CollegeSchedule V2.3 extraction agent. Target context: ${JSON.stringify(CONTEXT)}. Extract ONLY factual timetable classes relevant to this context and date range. Ignore unrelated programmes, terms, batches and dates. Do not reconcile, modify or replace the authoritative V1 timetable. Extract topic and teacher/faculty when explicitly present. Extract venue when explicitly present; otherwise null. Never infer missing values. Preserve useful source wording in raw_text. Use YYYY-MM-DD dates and HH:MM times when explicit. Return only the required structured schema.`,
    }];

    for (const file of body.files) {
      if (typeof file?.name !== "string" || typeof file?.mime_type !== "string" || typeof file?.data_base64 !== "string") {
        return response({ error: "Each file requires name, mime_type and data_base64" }, 400);
      }
      if (file.mime_type === "application/pdf") {
        content.push({ type: "file", file: { filename: file.name, file_data: dataUrl(file.mime_type, file.data_base64) } });
      } else if (/^image\/(png|jpeg|webp|gif)$/.test(file.mime_type)) {
        content.push({ type: "image_url", image_url: { url: dataUrl(file.mime_type, file.data_base64) } });
      } else if (["text/plain", "text/csv", "application/json"].includes(file.mime_type)) {
        content.push({ type: "text", text: `\nSOURCE FILE: ${file.name}\n${atob(file.data_base64)}` });
      } else {
        return response({ error: `Unsupported MIME type: ${file.mime_type}` }, 415);
      }
    }

    const upstream = await fetch(OPENROUTER_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "https://quare-albus.github.io/CollegeSchedule/",
        "X-Title": "CollegeSchedule Schedule Agent",
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0,
        messages: [{ role: "user", content }],
        response_format: {
          type: "json_schema",
          json_schema: { name: "schedule_extraction", strict: true, schema },
        },
        plugins: [{ id: "file-parser", pdf: { engine: "mistral-ocr" } }],
      }),
    });

    const payload = await upstream.json();
    if (!upstream.ok) return response({ error: "OpenRouter request failed", status: upstream.status, details: payload }, 502);

    const raw = payload?.choices?.[0]?.message?.content;
    const parsed = typeof raw === "string" ? JSON.parse(raw) : raw;
    return response({ ok: true, model: MODEL, context: CONTEXT, files: body.files.map((f: { name: string }) => f.name), ...parsed });
  } catch (error) {
    return response({ error: error instanceof Error ? error.message : String(error) }, 500);
  }
});
