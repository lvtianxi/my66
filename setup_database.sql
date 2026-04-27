-- =====================================================================
-- 66专属网站 · Supabase 数据库完整建库脚本
-- 使用方法：在 Supabase SQL Editor 中粘贴执行（选 Run and enable RLS）
-- 注意：执行前请先在 Supabase 中手动删除已有的表，再执行此脚本
-- =====================================================================


-- ===================
-- 第1步：删除旧表（如果存在）
-- ===================
-- 先删有外键依赖的子表
DROP TABLE IF EXISTS public.moment_comments CASCADE;
DROP TABLE IF EXISTS public.moments CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.capsules CASCADE;
DROP TABLE IF EXISTS public.gallery_uploads CASCADE;
DROP TABLE IF EXISTS public.wishes CASCADE;
DROP TABLE IF EXISTS public.video_uploads CASCADE;


-- ===================
-- 第2步：创建7张表（含约束、外键）
-- ===================

-- ① 时间胶囊
CREATE TABLE public.capsules (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  msg text NOT NULL CHECK (char_length(msg) <= 500),
  unlock_date date NOT NULL,
  created_date text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT capsules_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.capsules IS '时间胶囊 - 写给未来的话';

-- ② 相册上传
CREATE TABLE public.gallery_uploads (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  image_path text NOT NULL,
  description text NOT NULL DEFAULT '' CHECK (char_length(description) <= 100),
  time_label text NOT NULL DEFAULT '恋爱日常',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT gallery_uploads_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.gallery_uploads IS '爱看我家宝宝 - 上传的美照';

-- ③ 留言墙
CREATE TABLE public.messages (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  text text NOT NULL DEFAULT '' CHECK (char_length(text) <= 200),
  author text NOT NULL DEFAULT 'xiaobai' CHECK (author IN ('xiaobai', '66')),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.messages IS '心情留言墙 - 天天和66的留言';

-- ④ 朋友圈动态
CREATE TABLE public.moments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  author text NOT NULL DEFAULT 'xiaobai' CHECK (author IN ('xiaobai', '66')),
  content text NOT NULL DEFAULT '' CHECK (char_length(content) <= 500),
  images jsonb NOT NULL DEFAULT '[]'::jsonb,
  likes integer NOT NULL DEFAULT 0 CHECK (likes >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT moments_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.moments IS '朋友圈 - 记录生活点滴';

-- ⑤ 朋友圈评论（外键关联 moments，删动态自动删评论）
CREATE TABLE public.moment_comments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  moment_id bigint NOT NULL REFERENCES public.moments(id) ON DELETE CASCADE,
  author text NOT NULL DEFAULT 'xiaobai' CHECK (author IN ('xiaobai', '66')),
  content text NOT NULL DEFAULT '' CHECK (char_length(content) <= 200),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT moment_comments_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.moment_comments IS '朋友圈评论 - 删动态时自动级联删除';

-- ⑥ 共同心愿清单
CREATE TABLE public.wishes (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  text text NOT NULL DEFAULT '' CHECK (char_length(text) <= 100),
  author text NOT NULL DEFAULT 'xiaobai' CHECK (author IN ('xiaobai', '66')),
  done boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT wishes_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.wishes IS '共同心愿清单 - 一起去实现的事';

-- ⑦ 视频上传
CREATE TABLE public.video_uploads (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  video_path text NOT NULL,
  title text NOT NULL DEFAULT '上传的视频' CHECK (char_length(title) <= 50),
  description text NOT NULL DEFAULT '' CHECK (char_length(description) <= 200),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT video_uploads_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.video_uploads IS '视频上传 - 视频回忆';


-- ===================
-- 第3步：创建索引（加速查询排序）
-- ===================

-- 按时间倒序查询（留言墙、胶囊、朋友圈、心愿）
CREATE INDEX idx_capsules_created_at ON public.capsules (created_at DESC);
CREATE INDEX idx_messages_created_at ON public.messages (created_at DESC);
CREATE INDEX idx_moments_created_at ON public.moments (created_at DESC);
CREATE INDEX idx_wishes_created_at ON public.wishes (created_at DESC);

-- 相册按时间正序查询
CREATE INDEX idx_gallery_created_at ON public.gallery_uploads (created_at ASC);

-- 评论按动态ID查询 + 时间排序
CREATE INDEX idx_moment_comments_moment_id ON public.moment_comments (moment_id);
CREATE INDEX idx_moment_comments_created_at ON public.moment_comments (created_at ASC);

-- 视频按时间正序查询
CREATE INDEX idx_video_uploads_created_at ON public.video_uploads (created_at ASC);


-- ===================
-- 第4步：开启 RLS 并创建读写策略
-- ===================

-- 所有表开启行级安全
ALTER TABLE public.capsules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moment_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_uploads ENABLE ROW LEVEL SECURITY;

-- 所有表允许匿名读写（个人情侣网站，无需限制）
CREATE POLICY "Allow all for capsules" ON public.capsules FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for gallery_uploads" ON public.gallery_uploads FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for messages" ON public.messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for moments" ON public.moments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for moment_comments" ON public.moment_comments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for wishes" ON public.wishes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for video_uploads" ON public.video_uploads FOR ALL USING (true) WITH CHECK (true);


-- ===================
-- 第5步：Storage 存储桶权限
-- ===================
-- 注意：gallery-photos、moments-photos、video-uploads 三个桶需要先在 Supabase 控制台创建并设为 Public
-- 下面的策略用 IF NOT EXISTS 避免重复创建报错

-- 删除可能已存在的旧策略
DROP POLICY IF EXISTS "Allow public select gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow public upload gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow public update gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow public delete gallery" ON storage.objects;
DROP POLICY IF EXISTS "Allow public select moments" ON storage.objects;
DROP POLICY IF EXISTS "Allow public upload moments" ON storage.objects;
DROP POLICY IF EXISTS "Allow public update moments" ON storage.objects;
DROP POLICY IF EXISTS "Allow public delete moments" ON storage.objects;
DROP POLICY IF EXISTS "Allow public select video" ON storage.objects;
DROP POLICY IF EXISTS "Allow public upload video" ON storage.objects;
DROP POLICY IF EXISTS "Allow public update video" ON storage.objects;
DROP POLICY IF EXISTS "Allow public delete video" ON storage.objects;

-- gallery-photos 桶（读/写/改/删）
CREATE POLICY "Allow public select gallery" ON storage.objects FOR SELECT USING (bucket_id = 'gallery-photos');
CREATE POLICY "Allow public upload gallery" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'gallery-photos');
CREATE POLICY "Allow public update gallery" ON storage.objects FOR UPDATE USING (bucket_id = 'gallery-photos');
CREATE POLICY "Allow public delete gallery" ON storage.objects FOR DELETE USING (bucket_id = 'gallery-photos');

-- moments-photos 桶（读/写/改/删）
CREATE POLICY "Allow public select moments" ON storage.objects FOR SELECT USING (bucket_id = 'moments-photos');
CREATE POLICY "Allow public upload moments" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'moments-photos');
CREATE POLICY "Allow public update moments" ON storage.objects FOR UPDATE USING (bucket_id = 'moments-photos');
CREATE POLICY "Allow public delete moments" ON storage.objects FOR DELETE USING (bucket_id = 'moments-photos');

-- video-uploads 桶（读/写/改/删）
CREATE POLICY "Allow public select video" ON storage.objects FOR SELECT USING (bucket_id = 'video-uploads');
CREATE POLICY "Allow public upload video" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'video-uploads');
CREATE POLICY "Allow public update video" ON storage.objects FOR UPDATE USING (bucket_id = 'video-uploads');
CREATE POLICY "Allow public delete video" ON storage.objects FOR DELETE USING (bucket_id = 'video-uploads');


-- ===================
-- 第6步：开启实时同步（跨设备自动刷新）
-- ===================

DO $$
BEGIN
  -- 尝试添加到 realtime publication，已存在则忽略
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.capsules; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.gallery_uploads; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.messages; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.moments; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.moment_comments; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.wishes; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.video_uploads; EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;


-- =====================================================================
-- 执行完毕！去网站刷新页面测试各功能吧~
-- =====================================================================
