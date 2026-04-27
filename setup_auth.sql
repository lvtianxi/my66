-- =============================================
-- 66专属网站 - 登录认证表
-- 在 Supabase SQL Editor 中执行此脚本
-- =============================================

-- 创建认证凭据表
CREATE TABLE IF NOT EXISTS auth_credentials (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  display_name TEXT NOT NULL DEFAULT '用户',
  avatar_url TEXT DEFAULT 'images/头像/头像.jpg',
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin','user')),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 插入默认账号（和之前的 666 一致）
INSERT INTO auth_credentials (username, password, display_name, avatar_url, role) VALUES
  ('666', '666', '66', 'images/头像/66-1.jpg', 'admin'),
  ('xiaobai', '520', '小白', 'images/头像/小白1.jpg', 'admin')
ON CONFLICT (username) DO NOTHING;

-- 启用行级安全
ALTER TABLE auth_credentials ENABLE ROW LEVEL SECURITY;

-- RLS 策略：允许读取和更新（前端可验证登录 + 修改密码）
DROP POLICY IF EXISTS "allow_anon_select" ON auth_credentials;
CREATE POLICY "allow_anon_select" ON auth_credentials
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "allow_anon_update" ON auth_credentials;
CREATE POLICY "allow_anon_update" ON auth_credentials
  FOR UPDATE USING (true) WITH CHECK (true);

-- 启用 Realtime（可选，方便实时同步）
ALTER PUBLICATION supabase_realtime ADD TABLE auth_credentials;

-- =============================================
-- 时光轴动态条目表
-- =============================================
CREATE TABLE IF NOT EXISTS timeline_posts (
  id SERIAL PRIMARY KEY,
  tl_date TEXT NOT NULL,
  tl_text TEXT NOT NULL,
  images JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 关闭 RLS（个人网站无需行级安全）
ALTER TABLE timeline_posts DISABLE ROW LEVEL SECURITY;
GRANT ALL ON timeline_posts TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE timeline_posts_id_seq TO anon, authenticated;

ALTER PUBLICATION supabase_realtime ADD TABLE timeline_posts;

-- =============================================
-- 旅行动态条目表
-- =============================================
CREATE TABLE IF NOT EXISTS travel_posts (
  id SERIAL PRIMARY KEY,
  city TEXT NOT NULL,
  travel_date TEXT NOT NULL,
  description TEXT NOT NULL,
  images JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 关闭 RLS（个人网站无需行级安全）
ALTER TABLE travel_posts DISABLE ROW LEVEL SECURITY;
GRANT ALL ON travel_posts TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE travel_posts_id_seq TO anon, authenticated;

ALTER PUBLICATION supabase_realtime ADD TABLE travel_posts;

-- =============================================
-- Storage Buckets（需手动在 Dashboard 创建）：
--   timeline-photos （公开读）
--   travel-photos   （公开读）
-- =============================================

-- =============================================
-- 使用说明：
-- 1. 在 Supabase Dashboard → SQL Editor 执行此脚本
-- 2. 修改密码：UPDATE auth_credentials SET password='新密码', updated_at=now() WHERE username='666';
-- 3. 新增账号：INSERT INTO auth_credentials (username, password, display_name) VALUES ('新用户','密码','昵称');
-- 4. 禁用账号：UPDATE auth_credentials SET enabled=false WHERE username='666';
-- =============================================
