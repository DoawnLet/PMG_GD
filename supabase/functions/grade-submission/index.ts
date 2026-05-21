// supabase/functions/grade-submission/index.ts
// Deploy: supabase functions deploy grade-submission

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface GradeRequest {
  submission_id: string;
  strictness: "strict" | "balanced" | "lenient";
  language: "vi" | "en";
  special_note?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const body: GradeRequest = await req.json();
    const { submission_id, strictness, language, special_note } = body;

    // 1. Lấy thông tin bài nộp
    const { data: submission, error: subErr } = await supabase
      .from("submissions")
      .select("*, subjects(name, max_score, description)")
      .eq("id", submission_id)
      .single();

    if (subErr || !submission) {
      throw new Error(`Không tìm thấy bài nộp: ${subErr?.message}`);
    }

    // 2. Lấy tiêu chí chấm điểm
    const { data: criteria, error: criErr } = await supabase
      .from("criteria")
      .select("*")
      .eq("subject_id", submission.subject_id)
      .order("sort_order");

    if (criErr || !criteria?.length) {
      throw new Error("Không có tiêu chí chấm điểm");
    }

    // 3. Cập nhật trạng thái → grading
    await supabase
      .from("submissions")
      .update({ status: "grading" })
      .eq("id", submission_id);

    // 4. Xây dựng prompt
    const subject = submission.subjects;
    const maxScore = subject.max_score;
    const strictMap = {
      strict: "Chấm điểm nghiêm ngặt, yêu cầu cao về chất lượng.",
      balanced: "Chấm điểm công bằng và cân bằng.",
      lenient: "Chấm điểm dễ chịu, khuyến khích sinh viên.",
    };
    const criteriaText = criteria
      .map((c, i) => `${i + 1}. ${c.name} (tối đa ${c.max_points}đ): ${c.description}`)
      .join("\n");

    const langNote = language === "vi"
      ? "Viết tất cả nhận xét bằng tiếng Việt."
      : "Write all comments in English.";

    const prompt = `Bạn là giáo viên chấm điểm môn "${subject.name}".

ĐỀ BÀI / YÊU CẦU:
${subject.description}

TIÊU CHÍ CHẤM ĐIỂM (thang ${maxScore} điểm):
${criteriaText}

${special_note ? `LƯU Ý ĐẶC BIỆT:\n${special_note}\n` : ""}
${strictMap[strictness]}
${langNote}

BÀI LÀM CỦA SINH VIÊN (file: ${submission.file_name}):
---
${submission.content.substring(0, 5000)}
---

Hãy chấm điểm chi tiết. Trả về JSON DUY NHẤT, không kèm bất kỳ text nào khác:
{
  "total_score": <số thực, thang ${maxScore}>,
  "summary": "<nhận xét tổng quan 2-3 câu>",
  "strengths": "<điểm mạnh nổi bật>",
  "improvements": "<gợi ý cải thiện cụ thể>",
  "criteria_scores": [
    ${criteria
      .map(
        (c) =>
          `{"criteria_id": "${c.id}", "name": "${c.name}", "max": ${c.max_points}, "score": <số thực 0-${c.max_points}>, "comment": "<nhận xét ngắn gọn>"}`
      )
      .join(",\n    ")}
  ]
}`;

    // 5. Gọi Anthropic API
    const anthropicResp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": Deno.env.get("ANTHROPIC_API_KEY")!,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 1500,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!anthropicResp.ok) {
      const errText = await anthropicResp.text();
      throw new Error(`Anthropic API lỗi: ${errText}`);
    }

    const aiData = await anthropicResp.json();
    const rawText = aiData.content?.map((b: { text?: string }) => b.text || "").join("") || "";
    const clean = rawText.replace(/```json|```/g, "").trim();
    const result = JSON.parse(clean);

    // 6. Lưu kết quả vào Supabase
    await supabase
      .from("submissions")
      .update({
        status: "done",
        total_score: result.total_score,
        summary: result.summary,
        strengths: result.strengths,
        improvements: result.improvements,
        graded_at: new Date().toISOString(),
      })
      .eq("id", submission_id);

    // 7. Lưu điểm từng tiêu chí
    const scoreRows = result.criteria_scores.map((cs: {
      criteria_id: string;
      score: number;
      comment: string;
    }) => ({
      submission_id,
      criteria_id: cs.criteria_id,
      score: cs.score,
      comment: cs.comment,
    }));

    await supabase.from("submission_scores").upsert(scoreRows, {
      onConflict: "submission_id,criteria_id",
    });

    return new Response(
      JSON.stringify({ success: true, total_score: result.total_score }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    // Cập nhật trạng thái lỗi
    try {
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
      );
      const body = await req.clone().json().catch(() => ({}));
      if (body.submission_id) {
        await supabase
          .from("submissions")
          .update({ status: "error", error_message: String(error) })
          .eq("id", body.submission_id);
      }
    } catch (_) { /* ignore */ }

    return new Response(
      JSON.stringify({ error: String(error) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
