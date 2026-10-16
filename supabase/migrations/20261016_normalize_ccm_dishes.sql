-- CCM Menu normalized dish library
-- Applied to Supabase project kqnqvrwsdaxmclqfagct on 2026-10-16.
-- Serving defaults are stored once per dish; CCM_MENU.dish_id links schedule entries to dishes.

ALTER TABLE public."CCM_DISHES"
  ADD COLUMN IF NOT EXISTS default_serving text,
  ADD COLUMN IF NOT EXISTS default_quantity integer,
  ADD COLUMN IF NOT EXISTS carbs numeric,
  ADD COLUMN IF NOT EXISTS fat numeric,
  ADD COLUMN IF NOT EXISTS fiber numeric,
  ADD COLUMN IF NOT EXISTS nutrition_basis text NOT NULL DEFAULT 'per serving';

ALTER TABLE public."CCM_MENU"
  ADD COLUMN IF NOT EXISTS dish_id bigint;

CREATE UNIQUE INDEX IF NOT EXISTS ccm_dishes_normalized_name_uidx
  ON public."CCM_DISHES" (lower(btrim(dish_name)));

WITH normalized_menu AS (
  SELECT lower(btrim(food_item)) AS norm_name, min(btrim(food_item)) AS dish_name
  FROM public."CCM_MENU"
  GROUP BY lower(btrim(food_item))
),
serving_modes AS (
  SELECT norm_name, serving
  FROM (
    SELECT lower(btrim(food_item)) AS norm_name,
           serving,
           count(*) AS occurrences,
           row_number() OVER (
             PARTITION BY lower(btrim(food_item))
             ORDER BY count(*) DESC, serving ASC
           ) AS rn
    FROM public."CCM_MENU"
    GROUP BY lower(btrim(food_item)), serving
  ) ranked
  WHERE rn = 1
)
INSERT INTO public."CCM_DISHES"
  (dish_name, default_serving, default_quantity, nutrition_basis)
SELECT n.dish_name,
       CASE
         WHEN lower(n.dish_name) IN ('butter','jam') THEN NULL
         WHEN m.serving ~ '^[0-9]{1,2}$' THEN 'Number'
         ELSE m.serving
       END,
       CASE
         WHEN lower(n.dish_name) IN ('butter','jam') THEN NULL
         WHEN m.serving ~ '^[0-9]{1,2}$' THEN m.serving::integer
         ELSE NULL
       END,
       'per serving'
FROM normalized_menu n
LEFT JOIN serving_modes m ON m.norm_name = n.norm_name
WHERE NOT EXISTS (
  SELECT 1 FROM public."CCM_DISHES" d
  WHERE lower(btrim(d.dish_name)) = n.norm_name
);

UPDATE public."CCM_MENU" m
SET dish_id = d.id
FROM public."CCM_DISHES" d
WHERE lower(btrim(m.food_item)) = lower(btrim(d.dish_name))
  AND m.dish_id IS DISTINCT FROM d.id;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ccm_menu_dish_id_fkey'
      AND conrelid = 'public."CCM_MENU"'::regclass
  ) THEN
    ALTER TABLE public."CCM_MENU"
      ADD CONSTRAINT ccm_menu_dish_id_fkey
      FOREIGN KEY (dish_id) REFERENCES public."CCM_DISHES"(id)
      ON UPDATE CASCADE ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ccm_dishes_default_serving_check'
      AND conrelid = 'public."CCM_DISHES"'::regclass
  ) THEN
    ALTER TABLE public."CCM_DISHES"
      ADD CONSTRAINT ccm_dishes_default_serving_check
      CHECK (
        default_serving IS NULL OR
        default_serving IN ('Cup','Small bowl','Large bowl','1 standard rice scoop (kharandi)','Number')
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ccm_dishes_default_quantity_check'
      AND conrelid = 'public."CCM_DISHES"'::regclass
  ) THEN
    ALTER TABLE public."CCM_DISHES"
      ADD CONSTRAINT ccm_dishes_default_quantity_check
      CHECK (default_quantity IS NULL OR default_quantity BETWEEN 0 AND 99);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS ccm_menu_dish_id_idx ON public."CCM_MENU"(dish_id);

ALTER TABLE public."CCM_DISHES" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can read CCM dishes" ON public."CCM_DISHES";
CREATE POLICY "Public can read CCM dishes"
  ON public."CCM_DISHES" FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "Public can update CCM dish defaults and nutrition" ON public."CCM_DISHES";
CREATE POLICY "Public can update CCM dish defaults and nutrition"
  ON public."CCM_DISHES" FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

GRANT SELECT ON TABLE public."CCM_DISHES" TO anon, authenticated;
REVOKE UPDATE ON TABLE public."CCM_DISHES" FROM anon, authenticated;
GRANT UPDATE (default_serving, default_quantity, calories, protein, carbs, fat, fiber, nutrition_basis)
  ON TABLE public."CCM_DISHES" TO anon, authenticated;

REVOKE UPDATE ON TABLE public."CCM_MENU" FROM anon, authenticated;
REVOKE UPDATE (serving) ON TABLE public."CCM_MENU" FROM anon, authenticated;
DROP POLICY IF EXISTS "Public can update CCM serving only" ON public."CCM_MENU";
