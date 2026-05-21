-- =====================================================
-- PMG GRADING APP - Supabase Schema
-- Chạy trong Supabase SQL Editor
-- =====================================================

-- 1. Bảng môn học / kỳ thi
CREATE TABLE IF NOT EXISTS public.subjects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL DEFAULT 'Phương pháp Giải quyết Vấn đề (PMG)',
  max_score   INTEGER NOT NULL DEFAULT 10 CHECK (max_score IN (10, 100)),
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Bảng tiêu chí chấm điểm
CREATE TABLE IF NOT EXISTS public.criteria (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id  UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  max_points  NUMERIC(5,2) NOT NULL DEFAULT 2,
  description TEXT,
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Bảng bài nộp
CREATE TABLE IF NOT EXISTS public.submissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id      UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  file_name       TEXT NOT NULL,
  student_name    TEXT,                    -- Tên sinh viên (nếu có)
  content         TEXT NOT NULL,           -- Nội dung bài làm
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'grading', 'done', 'error')),
  total_score     NUMERIC(5,2),
  summary         TEXT,                    -- Nhận xét tổng quan
  strengths       TEXT,                    -- Điểm mạnh
  improvements    TEXT,                    -- Cần cải thiện
  error_message   TEXT,
  graded_at       TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Bảng điểm từng tiêu chí
CREATE TABLE IF NOT EXISTS public.submission_scores (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id   UUID REFERENCES public.submissions(id) ON DELETE CASCADE,
  criteria_id     UUID REFERENCES public.criteria(id) ON DELETE CASCADE,
  score           NUMERIC(5,2) NOT NULL DEFAULT 0,
  comment         TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(submission_id, criteria_id)
);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_criteria_subject     ON public.criteria(subject_id);
CREATE INDEX IF NOT EXISTS idx_submissions_subject  ON public.submissions(subject_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status   ON public.submissions(status);
CREATE INDEX IF NOT EXISTS idx_scores_submission    ON public.submission_scores(submission_id);

-- =====================================================
-- RLS (Row Level Security) - Tắt cho nội bộ
-- Bật lại nếu cần multi-user
-- =====================================================
ALTER TABLE public.subjects          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.criteria          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_scores ENABLE ROW LEVEL SECURITY;

-- Policy: Cho phép tất cả (dùng service_role key từ Edge Function)
CREATE POLICY "Allow all for service_role" ON public.subjects          FOR ALL USING (true);
CREATE POLICY "Allow all for service_role" ON public.criteria          FOR ALL USING (true);
CREATE POLICY "Allow all for service_role" ON public.submissions       FOR ALL USING (true);
CREATE POLICY "Allow all for service_role" ON public.submission_scores FOR ALL USING (true);

-- =====================================================
-- SEED DATA - Môn PMG mặc định
-- =====================================================
DO $$
DECLARE
  subj_id UUID;
BEGIN
  INSERT INTO public.subjects (name, max_score, description)
  VALUES (
    'Phương pháp Giải quyết Vấn đề (PMG)',
    10,
    'Bài tập vận dụng phương pháp giải quyết vấn đề để phân tích và đề xuất giải pháp cho một tình huống thực tế.'
  )
  RETURNING id INTO subj_id;

  INSERT INTO public.criteria (subject_id, name, max_points, description, sort_order) VALUES
    (subj_id, 'Xác định vấn đề',          2, 'Nhận diện đúng và rõ ràng vấn đề cần giải quyết, phạm vi ảnh hưởng', 1),
    (subj_id, 'Phân tích nguyên nhân',    2, 'Phân tích nguyên nhân gốc rễ (5 Whys / Fishbone), logic và đầy đủ',  2),
    (subj_id, 'Đề xuất giải pháp',        2, 'Đề xuất ≥2 giải pháp khả thi, có tính sáng tạo và thực tiễn',        3),
    (subj_id, 'Lập kế hoạch hành động',   2, 'Kế hoạch triển khai cụ thể (ai, làm gì, khi nào), đo lường được',    4),
    (subj_id, 'Trình bày và lập luận',    2, 'Cấu trúc rõ ràng, lập luận logic, diễn đạt tốt, dẫn chứng phù hợp', 5);
END $$;
